Shader "srp/CrossFilter_Filter"
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
            NAME "CROSSFILTER_GAUSSIAN_VERT"

            HLSLPROGRAM
            float4 _BlitTexture_TexelSize;
            const static float weight[3] = { 0.38774, 0.24477, 0.06136 };
            // const static float weight[5] = { 227027, 0.1945946, 0.1216216, 0.054054, 0.016216 };

            half4 frag(Varyings IN) : SV_Target
            {
                float3 blitTex = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_PointClamp, IN.texcoord).rgb;
                float3 result = blitTex * weight[0];
                for (int i = 1; i < 3; ++i)
                {
                    result += SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_PointClamp, IN.texcoord + float2(_BlitTexture_TexelSize.x * i, 0)).rgb * weight[i];
                    result += SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_PointClamp, IN.texcoord - float2(_BlitTexture_TexelSize.x * i, 0)).rgb * weight[i];
                }
                return half4(result, 1);
            }
            ENDHLSL
        }

        Pass // 1
        {
            NAME "CROSSFILTER_GAUSSIAN_HORIZ"

            HLSLPROGRAM
            float4 _BlitTexture_TexelSize;

            const static float weight[3] = { 0.38774, 0.24477, 0.06136 };
            // const static float weight[5] = { 227027, 0.1945946, 0.1216216, 0.054054, 0.016216 };

            half4 frag(Varyings IN) : SV_Target
            {
                float3 blitTex = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_PointClamp, IN.texcoord).rgb;
                float3 result = blitTex * weight[0];
                for (int i = 1; i < 3; ++i)
                {
                    result += SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_PointClamp, IN.texcoord + float2(0, _BlitTexture_TexelSize.y * i)).rgb * weight[i];
                    result += SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_PointClamp, IN.texcoord - float2(0, _BlitTexture_TexelSize.y * i)).rgb * weight[i];
                }
                return half4(result, 1);
            }
            ENDHLSL
        }

        Pass // 2
        {
            NAME "CROSSFILTER_STAR_RAY"

            HLSLPROGRAM
            static const int MAX_SAMPLES = 16;      // 최대샘플링수
            float4 _avSampleOffsets[MAX_SAMPLES];	// 샘플링위치
            float4 _avSampleWeights[MAX_SAMPLES];	// 샘플링가중치

            half4 frag(Varyings IN) : SV_Target
            {
                float4 result = 0;
                for (int i = 0; i < 8; ++i)
                {
                    float2 uvOffset = _avSampleOffsets[i].xy;
                    float4 blitTex = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_PointClamp, IN.texcoord + uvOffset);
                    result += _avSampleWeights[i] * blitTex;
                }
                return result;
            }
            ENDHLSL
        }

        Pass // 3
        {
            NAME "CROSSFILTER_MERGE_STAR"

            HLSLPROGRAM
            TEXTURE2D(_StarTex2);    SAMPLER(sampler_StarTex2);
            TEXTURE2D(_StarTex3);    SAMPLER(sampler_StarTex3);
            TEXTURE2D(_StarTex4);    SAMPLER(sampler_StarTex4);
            TEXTURE2D(_StarTex5);    SAMPLER(sampler_StarTex5);
            TEXTURE2D(_StarTex6);    SAMPLER(sampler_StarTex6);
            TEXTURE2D(_StarTex7);    SAMPLER(sampler_StarTex7);

            half4 frag(Varyings IN) : SV_Target
            {
                float4 result = (
                    SAMPLE_TEXTURE2D(_StarTex2, sampler_StarTex2, IN.texcoord)
                    + SAMPLE_TEXTURE2D(_StarTex3, sampler_StarTex3, IN.texcoord)
                    + SAMPLE_TEXTURE2D(_StarTex4, sampler_StarTex4, IN.texcoord)
                    + SAMPLE_TEXTURE2D(_StarTex5, sampler_StarTex5, IN.texcoord)
                    + SAMPLE_TEXTURE2D(_StarTex6, sampler_StarTex6, IN.texcoord)
                    + SAMPLE_TEXTURE2D(_StarTex7, sampler_StarTex7, IN.texcoord)
                ) / 6.0;
                return result;
            }
            ENDHLSL
        }
    }
}
