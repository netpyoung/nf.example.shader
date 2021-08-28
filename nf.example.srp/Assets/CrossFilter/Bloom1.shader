Shader "srp/Bloom1"
{
    Properties
    {
    }

    SubShader
    {
        Pass // 0
        {
            NAME "BLOOM_THRESHOLD"

            Cull Back
            ZWrite Off
            ZTest Off

            HLSLPROGRAM
            #pragma target 3.5

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _MainTex_TexelSize;
            CBUFFER_END

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
                float4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);

                mainTex.rgb -= 1.5;
                mainTex = max(mainTex, 0) * 3;

                return mainTex;
               /* float4 brightColor = 0;
                float3 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;

                float brightness = dot(mainTex, float3(0.2126, 0.7152, 0.0722));
                if (brightness > 0.9)
                {
                    brightColor = half4(mainTex, 1);
                }
                return brightColor;*/
            }
            ENDHLSL
        }

        Pass // 1
        {
            NAME "BLOOM_COMPOSITE"

            Cull Off
            ZWrite Off
            ZTest Off

            HLSLPROGRAM
            #pragma target 3.5

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);            SAMPLER(sampler_MainTex);
            TEXTURE2D(_BloomBlurTex);       SAMPLER(sampler_BloomBlurTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _MainTex_TexelSize;
            CBUFFER_END

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
                float3 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;
                float3 bloomBlurTex = SAMPLE_TEXTURE2D(_BloomBlurTex, sampler_BloomBlurTex, IN.uv).rgb;
                return half4(mainTex + bloomBlurTex, 1);
            }
            ENDHLSL
        }
    }
}
