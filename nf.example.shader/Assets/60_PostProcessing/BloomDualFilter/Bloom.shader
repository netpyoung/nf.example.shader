Shader "srp/Bloom"
{
    Properties
    {
        [HideInInspector] _MainTex("UI Texture", 2D) = "white" {}
        // [HideInInspector] _BloomBlurTex("UI Texture", 2D) = "white" {}
        // [HideInInspector] _BloomNonBlurTex("UI Texture", 2D) = "white" {}
    }

    SubShader
    {
        Pass
        {
            NAME "BLOOM_THRESHOLD"

            Cull Back
            ZWrite Off

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
                float4 brightColor = 0;
                float3 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;

                float brightness = dot(mainTex, float3(0.2126, 0.7152, 0.0722));
                if (brightness > 0.99)
                {
                    brightColor = half4(mainTex, 1);
                }
                return brightColor;
            }
            ENDHLSL
        }

        Pass
        {
            NAME "BLOOM_COMPOSITE"

            Cull Back
            ZWrite Off

            HLSLPROGRAM
            #pragma target 3.5

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);            SAMPLER(sampler_MainTex);
            TEXTURE2D(_BloomBlurTex);       SAMPLER(sampler_BloomBlurTex);
            TEXTURE2D(_BloomNonBlurTex);    SAMPLER(sampler_BloomNonBlurTex);


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
                float3 bloomNonBlurTex = SAMPLE_TEXTURE2D(_BloomNonBlurTex, sampler_BloomNonBlurTex, IN.uv).rgb;
             
                // return half4(bloomNonBlurTex, 1);
                // return half4(bloomBlurTex, 1);
                return half4(mainTex + bloomBlurTex + bloomNonBlurTex, 1);
            }
            ENDHLSL
        }
    }
}
