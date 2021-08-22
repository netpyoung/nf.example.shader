Shader "srp/DualFilter"
{
    // ref: [SIGGRAPH2015 - Bandwidth-efficient Graphics](https://community.arm.com/cfs-file/__key/communityserver-blogs-components-weblogfiles/00-00-00-20-66/siggraph2015_2D00_mmg_2D00_marius_2D00_notes.pdf)

    Properties
    {
        [HideInInspector] _MainTex("UI Texture", 2D) = "white" {}
    }

    SubShader
    {
        Pass // 0
        {
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
                float i = 0.5;

                half3 color;
                color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb * 4.0;
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + float2(i, i) * res).rgb;
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + float2(i, -i) * res).rgb;
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + float2(-i, i) * res).rgb;
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + float2(-i, -i) * res).rgb;
                color *= 0.125; // color /= 8.0;

                return half4(color, 1);
            }
            ENDHLSL
        }

        Pass // 1
        {
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
                float i = 0.5;

                half3 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + float2(i * 2, 0) * res).rgb;
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + float2(-i * 2, 0) * res).rgb;
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + float2(0, i * 2) * res).rgb;
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + float2(0, -i * 2) * res).rgb;
                
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + float2(i, i) * res).rgb * 2.0;
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + float2(-i, i) * res).rgb * 2.0;
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + float2(i, -i) * res).rgb * 2.0;
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + float2(-i, -i) * res).rgb * 2.0;

                color *= 0.08334; // color /= 12.0;

                return half4(color, 1);
            }
            ENDHLSL
        }
    }
}
