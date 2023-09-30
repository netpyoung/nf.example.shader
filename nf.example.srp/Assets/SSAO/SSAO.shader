Shader "srp/SSAO"
{
    Properties
    {
        _RandTex("_RandTex", 2D) = "white" {}
        _Scale("_Scale", Range(0, 10)) = 0.5
        _Radius("_Radius", Range(0.0002, 10)) = 0.05
        _Amount("_Amount", Range(0, 50)) = 1
        _Bias("_Bias", Range(0, 0.8)) = 0.5
    }

    SubShader
    {
        Cull Back
        ZWrite Off
        ZTest Off

        HLSLINCLUDE
        #pragma target 3.5
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"
        #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

        #pragma vertex Vert
        #pragma fragment frag
        ENDHLSL

        Pass // 0
        {
            NAME "PASS_SSAO_CALCUATE_OCULUSSION"

            HLSLPROGRAM
            TEXTURE2D(_RandTex);
            SAMPLER(sampler_RandTex);

            float _Scale;
            float _Amount;
            float _Bias;
            float _Radius;

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

            half4 frag(Varyings IN) : SV_Target
            {
                float3 srcPos = GetWorldSpacePosition(IN.texcoord);
                float3 srcNormal = GetNormal(IN.texcoord);


                const int SAMPLE_COUNT = 32;
                float AO = 0;

                // 매 계산마다 depth를 불러오니 => 32번 depth를 불러온다
                for (int i = 0; i < SAMPLE_COUNT; ++i)
                {
                    float2 dstUV = IN.texcoord + (float2(Random(IN.texcoord.xy + i), Random(IN.texcoord.yx + i)) * 2 - 1) / _ScreenParams.xy * _Radius;
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

            HLSLPROGRAM
            TEXTURE2D(_AmbientOcclusionTex);
            SAMPLER(sampler_AmbientOcclusionTex);

            half4 frag(Varyings IN) : SV_Target
            {
                half4 blitTex = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_PointClamp, IN.texcoord);
                float ambientOcclusionTex = SAMPLE_TEXTURE2D(_AmbientOcclusionTex, sampler_AmbientOcclusionTex, IN.texcoord).r;
                // blitTex *= (1 - ambientOcclusionTex);
                blitTex *= ambientOcclusionTex;
                return blitTex;
            }
            ENDHLSL
        }
    }
}
