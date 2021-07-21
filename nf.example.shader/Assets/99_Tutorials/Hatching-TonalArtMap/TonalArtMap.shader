Shader "TonalArtMap"
{
    Properties
    {
        _MainTex("texture", 2D) = "white" {}
        _Hatch012Tex("_Hatch012Tex", 2D) = "white" {}
        _Hatch345Tex("_Hatch345Tex", 2D) = "white" {}

    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalRenderPipeline"
            "Queue" = "Geometry"
            "RenderType" = "Opaque"
        }

        Pass
        {
            NAME "TONAL_ART_MAP"

            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);
            TEXTURE2D(_Hatch012Tex);        SAMPLER(sampler_Hatch012Tex);
            TEXTURE2D(_Hatch345Tex);        SAMPLER(sampler_Hatch345Tex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            CBUFFER_END

            struct APPtoVS
            {
                float4 positionOS    : POSITION;
                float2 uv            : TEXCOORD0;
                float3 normalOS        : NORMAL;
            };

            struct VStoFS
            {
                float4 positionCS    : SV_POSITION;
                float2 uv            : TEXCOORD0;
                float3 weight012    : TEXCOORD1;
                float3 weight345    : TEXCOORD2;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

                float3 N = TransformObjectToWorldDir(IN.normalOS);
                float3 L = normalize(GetMainLight().direction);
                float LdotN = dot(L, N);

                // LdotN: [-1, 1] => factor: [0, 6]
                float factor = (LdotN + 1.0) * 3.0;

                // 총 6단계 영역으로 나눈다.
                OUT.weight012 = float3(
                1.0 - saturate(abs(factor - 5.0)),
                1.0 - saturate(abs(factor - 4.0)),
                1.0 - saturate(abs(factor - 3.0))
                );
                OUT.weight345 = float3(
                1.0 - saturate(abs(factor - 2.0)),
                1.0 - saturate(abs(factor - 1.0)),
                1.0 - saturate(factor)
                );
                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                
                half3 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;
                half3 hatch123Tex = SAMPLE_TEXTURE2D(_Hatch012Tex, sampler_Hatch012Tex, IN.uv).rgb;
                half3 hatch456Tex = SAMPLE_TEXTURE2D(_Hatch345Tex, sampler_Hatch345Tex, IN.uv).rgb;

                half3 color012 = saturate(dot((1 - hatch123Tex), IN.weight012));
                half3 color345 = saturate(dot((1 - hatch456Tex), IN.weight345));

                // return half4(IN.weight012, 1);
                // return half4(IN.weight345, 1);
                // return half4(color012, 1);
                // return half4(color345, 1);
                half3 hatchColor = 1 - (color012 + color345);
                return half4(mainTex * hatchColor , 1);
            }
            ENDHLSL
        }
    }
}
