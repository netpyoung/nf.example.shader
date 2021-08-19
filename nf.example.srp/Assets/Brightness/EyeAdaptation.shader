Shader "Hidden/EyeAdaptation"
{

    HLSLINCLUDE
    ENDHLSL

    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }

    SubShader
    {
        Pass // 0
        {
            Cull Off
            ZWrite Off
            ZTest Always

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);
            TEXTURE2D(_LumaAdaptTex);   SAMPLER(sampler_LumaAdaptTex);
            TEXTURE2D(_LumaCurrTex);    SAMPLER(sampler_LumaCurrTex);
            TEXTURE2D(_LumaPrevTex);    SAMPLER(sampler_LumaPrevTex);

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
                VertexPositionInputs vpi = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionCS = vpi.positionCS;
                OUT.uv = IN.uv;
                return OUT;
            }

            float3 ACES_Slim(float3 x)
            {
                // ref: https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/

                x *= 0.6;
                const float a = 2.51f;
                const float b = 0.03f;
                const float c = 2.43f;
                const float d = 0.59f;
                const float e = 0.14f;
                return saturate((x * (a * x + b)) / (x * (c * x + d) + e));
            }

            half3 TonemapFilmic_Hejl2015(half3 hdr, half whitePoint)
            {
                half4 vh = half4(hdr, whitePoint);
                half4 va = (1.425 * vh) + 0.05;
                half4 vf = ((vh * va + 0.004) / ((vh * (va + 0.55) + 0.0491))) - 0.0821;
                return vf.rgb / vf.aaa;
            }

            float3 Tonemap_Filmic(float3 color, float exposure)
            {
                color *= exposure;
                float3 x = max(0, color - 0.004);
                color = (x * (6.2 * x + 0.5)) / (x * (6.2 * x + 1.7) + 0.06);
                return saturate(color);
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                half adaptLuma = SAMPLE_TEXTURE2D(_LumaAdaptTex, sampler_LumaAdaptTex, float2(0, 0)).r;
                half currLuma = SAMPLE_TEXTURE2D(_LumaCurrTex, sampler_LumaCurrTex, float2(0, 0)).r;

                half3 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;
                half3 color = ACES_Slim(mainTex * (1 + (currLuma - adaptLuma)));
                return half4(color, 1);
            }
            ENDHLSL
        }
    }
}
