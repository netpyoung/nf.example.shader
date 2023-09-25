Shader "srp/DualFilter"
{
    // ref: [SIGGRAPH2015 - Bandwidth-efficient Graphics](https://community.arm.com/cfs-file/__key/communityserver-blogs-components-weblogfiles/00-00-00-20-66/siggraph2015_2D00_mmg_2D00_marius_2D00_notes.pdf)

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
        float4 _BlitTexture_TexelSize;

        ENDHLSL

        Pass // 0
        {
            NAME "DUALFILTER_DOWN"

            HLSLPROGRAM
            half4 frag(Varyings IN) : SV_Target
            {
                float2 res = _BlitTexture_TexelSize.xy;
                float i = 0.5; // scatter

                half3 color;
                color = SAMPLE_TEXTURE2D(_BlitTexture, sampler_PointClamp, IN.texcoord).rgb * 4.0;
                color += SAMPLE_TEXTURE2D(_BlitTexture, sampler_PointClamp, IN.texcoord + float2(i, i) * res).rgb;
                color += SAMPLE_TEXTURE2D(_BlitTexture, sampler_PointClamp, IN.texcoord + float2(i, -i) * res).rgb;
                color += SAMPLE_TEXTURE2D(_BlitTexture, sampler_PointClamp, IN.texcoord + float2(-i, i) * res).rgb;
                color += SAMPLE_TEXTURE2D(_BlitTexture, sampler_PointClamp, IN.texcoord + float2(-i, -i) * res).rgb;
                color *= 0.125; // color /= 8.0;

                return half4(color, 1);
            }
            ENDHLSL
        }

        Pass // 1
        {
            NAME "DUALFILTER_UP"

            HLSLPROGRAM
            half4 frag(Varyings IN) : SV_Target
            {
                float2 res = _BlitTexture_TexelSize.xy;
                float i = 0.5;
                
                half3 color = SAMPLE_TEXTURE2D(_BlitTexture, sampler_PointClamp, IN.texcoord + float2(i * 2, 0) * res).rgb;
                color += SAMPLE_TEXTURE2D(_BlitTexture, sampler_PointClamp, IN.texcoord + float2(-i * 2, 0) * res).rgb;
                color += SAMPLE_TEXTURE2D(_BlitTexture, sampler_PointClamp, IN.texcoord + float2(0, i * 2) * res).rgb;
                color += SAMPLE_TEXTURE2D(_BlitTexture, sampler_PointClamp, IN.texcoord + float2(0, -i * 2) * res).rgb;
                
                color += SAMPLE_TEXTURE2D(_BlitTexture, sampler_PointClamp, IN.texcoord + float2(i, i) * res).rgb * 2.0;
                color += SAMPLE_TEXTURE2D(_BlitTexture, sampler_PointClamp, IN.texcoord + float2(-i, i) * res).rgb * 2.0;
                color += SAMPLE_TEXTURE2D(_BlitTexture, sampler_PointClamp, IN.texcoord + float2(i, -i) * res).rgb * 2.0;
                color += SAMPLE_TEXTURE2D(_BlitTexture, sampler_PointClamp, IN.texcoord + float2(-i, -i) * res).rgb * 2.0;

                color *= 0.08334; // color /= 12.0;

                return half4(color, 1);
            }
            ENDHLSL
        }
    }
}