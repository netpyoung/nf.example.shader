Shader "Tone/GrayScale"
{
    Properties
    {
        _MainTex("texture", 2D) = "white" {}
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
            Name "TONE_GRAYSCALE"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
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

            const static half3x3 MAT_RGB_TO_YUV = {
                +0.299, +0.587, +0.114,
                -0.147, -0.289, +0.436,
                +0.615, -0.515, -0.100
            };

            const static half3x3 MAT_YUV_TO_RGB = {
                +1.0, +0.000, +1.140,
                +1.0, -0.396, -0.581,
                +1.0, +2.029, +0.000
            };

            half4 frag(VStoFS IN) : SV_Target
            {
                half3 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;
                half3 color = mul(MAT_RGB_TO_YUV[0], mainTex);
                return half4(color, 1);
            }
            ENDHLSL
        }
    }
}
