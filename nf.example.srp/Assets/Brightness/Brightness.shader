Shader "Hidden/Brightness"
{
    Properties
    {
        _AdaptionConstant("_AdaptionConstant", Float) = 1
    }

    SubShader
    {
        Cull Back
        ZWrite Off
        ZTest Off

        HLSLINCLUDE
        #pragma target 3.5
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
        #pragma vertex Vert
        #pragma fragment frag
        ENDHLSL

        Pass // 0
        {
            NAME "BRIGHTNESS_LUMA"

            HLSLPROGRAM
            half4 frag(Varyings IN) : SV_Target
            {
                half3 mainTex = SAMPLE_TEXTURE2D(_BlitTexture, sampler_PointClamp, IN.texcoord).rgb;

                const half3 W = half3(0.2125, 0.7154, 0.0721);
                half luma = dot(mainTex, W);
                half logLuma = log(luma);
                return half4(luma, logLuma, 0, 0);
            }
            ENDHLSL
        }

        Pass // 1
        {
            NAME "BRIGHTNESS_SPLIT"

            HLSLPROGRAM
            half4 frag(Varyings IN) : SV_Target
            {
                half2 mainTex = SAMPLE_TEXTURE2D_LOD(_BlitTexture, sampler_PointClamp, IN.texcoord, 10).rg;
                return half4(mainTex.r, mainTex.g, 0, 0);
            }
            ENDHLSL
        }

        Pass // 2
        {
            NAME "BRIGHTNESS_ADAPT"

            HLSLPROGRAM
            TEXTURE2D(_LumaAdaptPrevTex);
            SAMPLER(sampler_LumaAdaptPrevTex);

            float _AdaptionConstant;

            float SensitivityOfRod(float y)
            {
                return 0.04 / (0.04 + y);
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half lumaAverageCurr = SAMPLE_TEXTURE2D(_BlitTexture, sampler_PointClamp, float2(0, 0)).r;
                half lumaAdaptPrev = SAMPLE_TEXTURE2D(_LumaAdaptPrevTex, sampler_LumaAdaptPrevTex, float2(0, 0)).r;
                
                half _DeltaTime = unity_DeltaTime.x;
                half s = SensitivityOfRod(lumaAdaptPrev);
                half AdaptionConstant = s * 0.4 + (1 - s) * 0.1;

                half lumaAdaptCurr = lumaAdaptPrev
                    + (lumaAverageCurr - lumaAdaptPrev)
                    * (1.0 - exp(-_DeltaTime / AdaptionConstant * _AdaptionConstant));

                return half4(lumaAdaptCurr, 0, 0, 0);
            }
            ENDHLSL
        }
    }
}
