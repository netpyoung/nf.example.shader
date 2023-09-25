Shader "Hidden/EyeAdaptation"
{
    Properties
    {
        _Key("_Key", Float) = 1
    }

    SubShader
    {
        HLSLINCLUDE
        #pragma target 3.5
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
        #pragma vertex Vert
        #pragma fragment frag
        ENDHLSL

        Pass // 0
        {
            NAME "EYEADAPTATION"

            HLSLPROGRAM
            TEXTURE2D(_LumaAdaptCurrTex);
            SAMPLER(sampler_LumaAdaptCurrTex);

            TEXTURE2D(_LumaCurrTex);
            SAMPLER(sampler_LumaCurrTex);
            
            // for debug
            // TEXTURE2D(_TmpCurrMipmapTex);    SAMPLER(sampler_TmpCurrMipmapTex);
            
            float _Key;

            half AutoKey(half avgLum)
            {
                return saturate(1.5 - 1.5 / (avgLum * 0.1 + 1)) + 0.1;
            }

            float3 Reinhard_extended(float3 v, float max_white)
            {
                float3 numerator = v * (1.0f + (v / (max_white * max_white)));
                return numerator / (1.0f + v);
            }

            half4 frag(Varyings IN) : SV_Target
            {
                // for debug
                // return SAMPLE_TEXTURE2D_LOD(_TmpCurrMipmapTex, sampler_TmpCurrMipmapTex, IN.uv, 5).rrrr;
                // return exp(SAMPLE_TEXTURE2D_LOD(_TmpCurrMipmapTex, sampler_TmpCurrMipmapTex, IN.uv, 5).gggg);

                half3 mainTex = SAMPLE_TEXTURE2D(_BlitTexture, sampler_PointClamp, IN.texcoord).rgb;
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
