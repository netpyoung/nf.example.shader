Shader "ColorToMetal"
{
    // ref: https://cedil.cesa.or.jp/cedil_sessions/view/1892

    Properties
    {
        _MainTex("texture", 2D) = "white" {}
        _PickColor("_PickColor", Color) = (1, 1, 1, 0)
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
            Name "COLOR_TO_METAL"

            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature_local _ IS_UNCHARTED2

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            
            float3 _PickColor;
            CBUFFER_END

            struct APPtoVS
            {
                float4 positionOS    : POSITION;
                float2 uv            : TEXCOORD0;
                float3 normal        : NORMAL;
            };

            struct VStoFS
            {
                float4 positionCS    : SV_POSITION;
                float2 uv            : TEXCOORD0;
                float3 N            : TEXCOORD1;
                float3 positionWS    : TEXCOORD2;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                OUT.N = TransformObjectToWorldNormal(IN.normal);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);

                return OUT;
            }

            float3 RGBtoHSV(float3 c)
            {
                float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
                float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
                float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

                float d = q.x - min(q.w, q.y);
                float e = 1.0e-10;
                return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
            }

            float ColorToMetal(float3 basecolor, float3 pickColor)
            {
                float hueA = RGBtoHSV(pickColor.xyz).x;
                float hueB = RGBtoHSV(basecolor.xyz).x;
                if (hueA > 0.5)
                {
                    hueA = 1 - hueA;
                }
                if (hueB > 0.5)
                {
                    hueB = 1 - hueB;
                }
                float mask = abs(hueA - hueB);
                mask = smoothstep(0.3, 0.7, mask);
                return mask;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                half3 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;
                half3 color = ColorToMetal(mainTex, _PickColor);
                return half4(color, 1);

                return half4(mainTex + color, 1);
            }
            ENDHLSL
        }
    }
}
