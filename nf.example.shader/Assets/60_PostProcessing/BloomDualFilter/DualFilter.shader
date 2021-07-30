Shader "srp/DualFilter"
{
    Properties
    {
        [HideInInspector] _MainTex("UI Texture", 2D) = "white" {}
    }

    SubShader
    {
        Pass
        {
            NAME "DUALFILTER_DOWN"

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
                float2 res = _MainTex_TexelSize.xy;
                float i = 1;

                half3 color;
                color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb * 4.0;
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + float2(i, i) * res).rgb;
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + float2(i, -i) * res).rgb;
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + float2(-i, i) * res).rgb;
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + float2(-i, -i) * res).rgb;
                color /= 8.0;

                return half4(color, 1);
            }
            ENDHLSL
        }

        Pass
        {
            NAME "DUALFILTER_UP"

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
                float2 res = _MainTex_TexelSize.xy;
                float i = 1;

                half3 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + float2(i * 2, 0) * res).rgb;
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + float2(-i * 2, 0) * res).rgb;
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + float2(0, i * 2) * res).rgb;
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + float2(0, -i * 2) * res).rgb;
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + float2(i, i) * res).rgb * 2.0;
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + float2(-i, i) * res).rgb * 2.0;
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + float2(i, -i) * res).rgb * 2.0;
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + float2(-i, -i) * res).rgb * 2.0;

                color /= 12.0;

                return half4(color, 1);
            }
            ENDHLSL
        }
    }
}
