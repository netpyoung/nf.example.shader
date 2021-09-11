Shader "srp/SSAO"
{
    Properties
    {
        [HideInInspector] _MainTex("UI Texture", 2D) = "white" {}
        _RandTex("_RandTex", 2D) = "white" {}
        _Scale("_Scale", Range(0, 10)) = 0.5
        _Radius("_Radius", Range(0.0002, 10)) = 0.05
        _Amount("_Amount", Range(0, 50)) = 1
        _Bias("_Bias", Range(0, 0.8)) = 0.5
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
            TEXTURE2D(_RandTex);    SAMPLER(sampler_RandTex);
    

            float _Scale;
            float _Amount;
            float _Bias;
            float _Radius;

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

            inline float Random(in float2 uv)
            {
                // 렌덤텍스쳐 이용하는 방법
                // return SAMPLE_TEXTURE2D(_RandTex, sampler_RandTex, uv).r;

                // 그냥 계산하는 방법
                return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
            }

            float3 GetWorldSpacePosition(in float2 uv)
            {
                float sceneRawDepth = SampleSceneDepth(uv);
                return ComputeWorldSpacePosition(uv, sceneRawDepth, UNITY_MATRIX_I_VP);
            }

            float3 GetNormal(in float2 uv)
            {
                return SampleSceneNormals(uv);
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                float3 srcPos = GetWorldSpacePosition(IN.uv);
                float3 srcNormal = GetNormal(IN.uv);


                const int SAMPLE_COUNT = 32;
                float AO = 0;

                // 매 계산마다 depth를 불러오니 => 32번 depth를 불러온다
                for (int i = 0; i < SAMPLE_COUNT; ++i)
                {
                    float2 dstUV = IN.uv + (float2(Random(IN.uv.xy + i), Random(IN.uv.yx + i)) * 2 - 1) / _ScreenParams.xy * _Radius;
                    float3 dstPos = GetWorldSpacePosition(dstUV);

                    float3 distance = dstPos - srcPos;
                    float3 direction = normalize(distance);
                    float delta = length(distance) * _Scale;

                    AO += max(0, dot(srcNormal, direction) - _Bias) * (1 / (1 + delta)) * _Amount;
                }

                AO /= SAMPLE_COUNT;
                AO = 1 - AO;

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
                // mainTex *= (1 - ambientOcclusionTex);
                mainTex *= ambientOcclusionTex;
                return mainTex;
            }
            ENDHLSL
        }
    }
}
