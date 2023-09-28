Shader "srp/CrossFilter_Bloom"
{
    Properties
    {
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
            NAME "BLOOM_THRESHOLD"

            HLSLPROGRAM
            half4 frag(Varyings IN) : SV_Target
            {
                float4 blitTex = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_PointClamp, IN.texcoord);
                blitTex.rgb -= 1.5;
                blitTex = max(blitTex, 0) * 3;
                return blitTex;
               /* float4 brightColor = 0;
                float3 blitTex = SAMPLE_TEXTURE2D(_blitTex, sampler_blitTex, IN.uv).rgb;

                float brightness = dot(blitTex, float3(0.2126, 0.7152, 0.0722));
                if (brightness > 0.9)
                {
                    brightColor = half4(blitTex, 1);
                }
                return brightColor;*/
            }
            ENDHLSL
        }

        Pass // 1
        {
            NAME "BLOOM_COMPOSITE"

            HLSLPROGRAM
            TEXTURE2D(_BloomBlurTex);
            SAMPLER(sampler_BloomBlurTex);

            half4 frag(Varyings IN) : SV_Target
            {
                float3 blitTex = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_PointClamp, IN.texcoord).rgb;
                float3 bloomBlurTex = SAMPLE_TEXTURE2D(_BloomBlurTex, sampler_BloomBlurTex, IN.texcoord).rgb;
                return half4(blitTex + bloomBlurTex, 1);
            }
            ENDHLSL
        }
    }
}
