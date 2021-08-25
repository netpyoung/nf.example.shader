Shader "Hidden/EyeAdaptation"
{

    HLSLINCLUDE
    ENDHLSL

    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Key("_Key", Float) = 1
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
            TEXTURE2D(_LumaAdaptCurrTex);   SAMPLER(sampler_LumaAdaptCurrTex);
            TEXTURE2D(_LumaCurrTex);    SAMPLER(sampler_LumaCurrTex);
            
            // for debug
            // TEXTURE2D(_TmpCurrMipmapTex);    SAMPLER(sampler_TmpCurrMipmapTex);
            
            float _Key;

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

            half AutoKey(half avgLum)
            {
                return saturate(1.5 - 1.5 / (avgLum * 0.1 + 1)) + 0.1;
            }

            float3 Reinhard_extended(float3 v, float max_white)
            {
                float3 numerator = v * (1.0f + (v / (max_white * max_white)));
                return numerator / (1.0f + v);
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                // for debug
                // return SAMPLE_TEXTURE2D_LOD(_TmpCurrMipmapTex, sampler_TmpCurrMipmapTex, IN.uv, 5).rrrr;
                // return exp(SAMPLE_TEXTURE2D_LOD(_TmpCurrMipmapTex, sampler_TmpCurrMipmapTex, IN.uv, 5).gggg);

                half3 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;
                half lumaAverageCurr = SAMPLE_TEXTURE2D(_LumaCurrTex, sampler_LumaCurrTex, float2(0, 0)).r;
                half lumaAdaptCurr = SAMPLE_TEXTURE2D(_LumaAdaptCurrTex, sampler_LumaAdaptCurrTex, float2(0, 0)).r;

                // return lumaAdaptCurr;

                _Key = AutoKey(lumaAverageCurr);

                half3 color = mainTex * (_Key / (lumaAdaptCurr + 0.0001));
                color = Reinhard_extended(color, 1);
                return half4(color, 1);
            }
            ENDHLSL
        }
    }
}
