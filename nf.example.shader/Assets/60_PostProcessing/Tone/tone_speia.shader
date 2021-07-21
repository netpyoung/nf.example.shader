Shader "Tone/Sepia"
{
    Properties
    {
        _MainTex("texture", 2D) = "white" {}

        [Toggle(IS_YIQ)]_IsYIQ("Use YIQ?", Float) = 1
        _Y("_Y", Range(0.0, 2.0)) = 1.2
        _I("_I", Range(-1.0, 1.0)) = 0.22
        _Q("_Q", Range(-1.0, 1.0)) = 0.03
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
            Name "TONE_SEPIA"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature_local _ IS_YIQ

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float _Y;
            float _I;
            float _Q;
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

            const static half3x3 MAT_RGB_TO_YIQ = {
                +0.299, +0.587, +0.114,
                +0.596, -0.274, -0.322,
                +0.212, -0.523, +0.311
            };

            const static half3x3 MAT_YIQ_TO_RGB = {
                +1.0, +0.956, +0.621,
                +1.0, -0.272, -0.647,
                +1.0, -1.105, +1.702
            };

            const static half3x3 MAT_TO_SEPIA = {
                0.393, 0.769, 0.189,   // tRed
                0.349, 0.686, 0.168,   // tGreen
                0.272, 0.534, 0.131    // tBlue
            };

            half4 frag(VStoFS IN) : SV_Target
            {
                half3 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;
                #if IS_YIQ
                    half3 color = mul(MAT_RGB_TO_YIQ, mainTex);
                    color.r *= _Y;
                    color.g *= _I;
                    color.b *= _Q;
                    color = mul(MAT_YIQ_TO_RGB, color);
                    return half4(color, 1);
                #else
                    return half4(mul(MAT_TO_SEPIA, mainTex), 1);
                #endif
            }
            ENDHLSL
        }
    }
}
