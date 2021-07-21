Shader "Tone/Filmic"
{
    Properties
    {
        _MainTex("texture", 2D) = "white" {}

        [Toggle(IS_FILMIC)]_IsFilmic("Use Filmic?", Float) = 1
        _Exposure("_Exposure", Range(0.01, 5.0)) = 1
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalRenderPipeline"
            "Queue" = "Geometry"
            "RenderType" = "Opaque"
        }

        Pass
        {
            Name "TONE_FILMIC"

            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature_local _ IS_FILMIC

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float _Exposure;
            CBUFFER_END

            struct APPtoVS
            {
                float4 positionOS    : POSITION;
                float2 uv            : TEXCOORD0;
            };

            struct VStoFS
            {
                float4 positionCS    : SV_POSITION;
                float2 uv            : TEXCOORD0;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

                return OUT;
            }

            half3 TonemapFilmic(half3 color_Linear)
            {
                // optimized formula by Jim Hejl and Richard Burgess-Dawson
                half3 X = max(color_Linear - 0.004, 0.0);
                half3 result_Gamma = (X * (6.2 * X + 0.5)) / (X * (6.2 * X + 1.7) + 0.06);
                return pow(result_Gamma, 2.2); // convert Linear Color
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                half3 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;
                #if IS_FILMIC
                    half3 color = TonemapFilmic(mainTex * _Exposure);
                    return half4(color, 1);
                #else
                    return half4(mainTex * _Exposure, 1);
                #endif
            }
            ENDHLSL
        }
    }
}
