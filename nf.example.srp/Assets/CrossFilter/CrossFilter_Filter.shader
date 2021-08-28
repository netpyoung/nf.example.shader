Shader "srp/CrossFilter_Filter"
{
    Properties
    {
    }

    SubShader
    {
        Pass // 0
        {
            NAME "CROSSFILTER_GAUSSIAN_VERT"

            Cull Back
            ZWrite Off
            ZTest Off

            HLSLPROGRAM
            #pragma target 3.5

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            float4 _MainTex_TexelSize;
            const static float weight[3] = { 0.38774, 0.24477, 0.06136 };
            // const static float weight[5] = { 227027, 0.1945946, 0.1216216, 0.054054, 0.016216 };

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

            half4 frag(VStoFS IN) : SV_Target
            {
                float3 result = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb * weight[0];
                for (int i = 1; i < 3; ++i)
                {
                    result += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + float2(_MainTex_TexelSize.x * i, 0)).rgb * weight[i];
                    result += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv - float2(_MainTex_TexelSize.x * i, 0)).rgb * weight[i];
                }
                return half4(result, 1);
            }
            ENDHLSL
        }

        Pass // 1
        {
            NAME "CROSSFILTER_GAUSSIAN_HORIZ"

            Cull Back
            ZWrite Off
            ZTest Off

            HLSLPROGRAM
            #pragma target 3.5

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            float4 _MainTex_TexelSize;

            const static float weight[3] = { 0.38774, 0.24477, 0.06136 };
            // const static float weight[5] = { 227027, 0.1945946, 0.1216216, 0.054054, 0.016216 };
            
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

            half4 frag(VStoFS IN) : SV_Target
            {
                float3 result = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb * weight[0];
                for (int i = 1; i < 3; ++i)
                {
                    result += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + float2(0, _MainTex_TexelSize.y * i)).rgb * weight[i];
                    result += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv - float2(0, _MainTex_TexelSize.y * i)).rgb * weight[i];
                }
                return half4(result, 1);
            }
            ENDHLSL
        }

        Pass // 2
        {
            NAME "CROSSFILTER_STAR_RAY"

            Cull Back
            ZWrite Off
            ZTest Off

            HLSLPROGRAM
            #pragma target 3.5

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);

            static const int    MAX_SAMPLES = 16;    // 최대샘플링수
            float4 _avSampleOffsets[MAX_SAMPLES];	// 샘플링위치
            float4 _avSampleWeights[MAX_SAMPLES];	// 샘플링가중치

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

            half4 frag(VStoFS IN) : SV_Target
            {
                float4 result = 0;
                for (int i = 0; i < 8; ++i)
                {
                    result += _avSampleWeights[i] * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + _avSampleOffsets[i].xy);
                }
                return result;
            }
            ENDHLSL
        }

        Pass // 3
        {
            NAME "CROSSFILTER_MERGE_STAR"

            Cull Back
            ZWrite Off
            ZTest Off

            HLSLPROGRAM
            #pragma target 3.5

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_StarTex2);    SAMPLER(sampler_StarTex2);
            TEXTURE2D(_StarTex3);    SAMPLER(sampler_StarTex3);
            TEXTURE2D(_StarTex4);    SAMPLER(sampler_StarTex4);
            TEXTURE2D(_StarTex5);    SAMPLER(sampler_StarTex5);
            TEXTURE2D(_StarTex6);    SAMPLER(sampler_StarTex6);
            TEXTURE2D(_StarTex7);    SAMPLER(sampler_StarTex7);

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

            half4 frag(VStoFS IN) : SV_Target
            {
                float4 result = (
                    SAMPLE_TEXTURE2D(_StarTex2, sampler_StarTex2, IN.uv)
                    + SAMPLE_TEXTURE2D(_StarTex3, sampler_StarTex3, IN.uv)
                    + SAMPLE_TEXTURE2D(_StarTex4, sampler_StarTex4, IN.uv)
                    + SAMPLE_TEXTURE2D(_StarTex5, sampler_StarTex5, IN.uv)
                    + SAMPLE_TEXTURE2D(_StarTex6, sampler_StarTex6, IN.uv)
                    + SAMPLE_TEXTURE2D(_StarTex7, sampler_StarTex7, IN.uv)
                ) / 6.0;
                return result;
            }
            ENDHLSL
        }
    }
}
