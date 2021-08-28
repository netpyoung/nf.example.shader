Shader "srp/DualFilter1"
{
    Properties
    {
    }

    SubShader
    {
        Pass // 0
        {
            // two-pass Gaussian blur(Vert)
            NAME "DUALFILTER_DOWN"

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
            const static float weight[5] = { 0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216 };

            half4 frag(VStoFS IN) : SV_Target
            {
                float3 result = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb * weight[0];
                for (int i = 1; i < 5; ++i)
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
            // two-pass Gaussian blur(Horiz)
            NAME "DUALFILTER_UP"

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

            const static float weight[5] = { 0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216 };

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
                for (int i = 1; i < 5; ++i)
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
            // Star Ray
            NAME "DUALFILTER_UP"

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
            // Star Ray Sum
            NAME "DUALFILTER_UP"

            Cull Back
            ZWrite Off
            ZTest Off

            HLSLPROGRAM
            #pragma target 3.5

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_S0Tex);    SAMPLER(sampler_S0Tex);
            TEXTURE2D(_S1Tex);    SAMPLER(sampler_S1Tex);
            TEXTURE2D(_S2Tex);    SAMPLER(sampler_S2Tex);
            TEXTURE2D(_S3Tex);    SAMPLER(sampler_S3Tex);
            TEXTURE2D(_S4Tex);    SAMPLER(sampler_S4Tex);
            TEXTURE2D(_S5Tex);    SAMPLER(sampler_S5Tex);

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
                    SAMPLE_TEXTURE2D(_S0Tex, sampler_S0Tex, IN.uv)
                    + SAMPLE_TEXTURE2D(_S1Tex, sampler_S1Tex, IN.uv)
                    + SAMPLE_TEXTURE2D(_S2Tex, sampler_S2Tex, IN.uv)
                    + SAMPLE_TEXTURE2D(_S3Tex, sampler_S3Tex, IN.uv)
                    + SAMPLE_TEXTURE2D(_S4Tex, sampler_S4Tex, IN.uv)
                    + SAMPLE_TEXTURE2D(_S5Tex, sampler_S5Tex, IN.uv)
                ) / 6.0;
                return result;
            }
            ENDHLSL
        }
    }
}
