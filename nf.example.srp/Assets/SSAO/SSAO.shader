Shader "srp/SSAO"
{
    Properties
    {
        [HideInInspector] _MainTex("UI Texture", 2D) = "white" {}
    }

    SubShader
    {
        Pass // 0
        {
            NAME "PASS_SSAO_CALCUATE_OCULUSSION"

            Cull Back
            ZWrite Off
            ZTest Off

            HLSLPROGRAM
            #pragma target 3.5

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _MainTex_TexelSize;
            CBUFFER_END

            struct APPtoVS
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
            };

            struct VStoFS
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float4 positionNDC  : TEXCOORD1;
                float3 positionVS   : TEXCOORD2;
                float3 toViewVectorWS : TEXCOORD3;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);
                VertexPositionInputs inputs = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionCS = inputs.positionCS;
                OUT.positionNDC = inputs.positionNDC;
                OUT.positionVS = inputs.positionVS;

                OUT.toViewVectorWS = _WorldSpaceCameraPos - inputs.positionWS;
                OUT.uv = IN.uv;
                return OUT;
            }

            float3 GetWorldSpacePosition(in float2 screenUV, in float fragmentEyeDepth, in float3 toViewVectorWS)
            {
                float sceneRawDepth = SampleSceneDepth(screenUV);
                float sceneEyeDepth = LinearEyeDepth(sceneRawDepth, _ZBufferParams);
                float3 scenePositionWS = _WorldSpaceCameraPos + (-toViewVectorWS / fragmentEyeDepth) * sceneEyeDepth;
                return scenePositionWS;
            }
            
            inline float Random(in float2 uv)
            {
                return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                float2 screenUV = (IN.positionNDC.xy / IN.positionNDC.w);
                float fragmentEyeDepth = -IN.positionVS.z;
                float3 srcPositionWS = GetWorldSpacePosition(screenUV, fragmentEyeDepth, IN.toViewVectorWS);
                //return half4(srcPositionWS, 1);

                float3 srcNormal = SampleSceneNormals(IN.uv);
                //return half4(normal, 1);

                float AO = 0;
                float _Scale = 1;
                float _Amount = 1;
                float _Radius = 1;
                float _Bias = 0.5f;

                for (int iter = 0; iter < 32; ++iter)
                {
                    float2 sampleUV = IN.uv + (float2(Random(IN.uv.xy + iter), Random(IN.uv.yx + iter)) * 2 - 1) / _ScreenParams.xy * _Radius;
                    float3 samplePositionWS = GetWorldSpacePosition(sampleUV, fragmentEyeDepth, IN.toViewVectorWS);

                    float3 distance = samplePositionWS - srcPositionWS;
                    float3 direction = normalize(distance);
                    float delta = length(distance) * _Scale;

                    AO += max(0, dot(srcNormal, direction) - _Bias) * (1 / (1 + delta)) * _Amount;
                }

                AO /= 32;

                return half4(AO.xxx, 1);
            }
            ENDHLSL
        }

        Pass // 1
        {
            NAME "PASS_SSAO_COMBINE"

            Cull Off
            ZWrite Off
            ZTest Off

            HLSLPROGRAM
            #pragma target 3.5

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);            SAMPLER(sampler_MainTex);
            TEXTURE2D(_AmbientOcclusionTex);       SAMPLER(sampler_AmbientOcclusionTex);

            struct APPtoVS
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
            };

            struct VStoFS
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                float ambientOcclusionTex = SAMPLE_TEXTURE2D(_AmbientOcclusionTex, sampler_AmbientOcclusionTex, IN.uv).r;
                mainTex *= (1 - ambientOcclusionTex);
                return mainTex;
            }
            ENDHLSL
        }
    }
}
