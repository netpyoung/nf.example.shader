Shader "Filter/Blur_Kawase"
{
    Properties
    {
        [NoScaleOffset] _MainTex("texture", 2D) = "white" {}
        _TexelScale("_TexelScale", Range(1, 10)) = 1
        [Toggle(IS_BLUR)]_IsBlur("Apply Blur?", Float) = 1

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
            Name "FILTER_KAWASE"

            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            #pragma target 3.5

            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature_local _ IS_BLUR

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            
            CBUFFER_START(UnityPerMaterial)
            float2 _MainTex_TexelSize;
            half _TexelScale;
            CBUFFER_END

            struct APPtoVS
            {
                float4 positionOS    : POSITION;
                float2 uv            : TEXCOORD0;
            };

            struct VStoFS
            {
                float4 positionCS    : SV_POSITION;
                float2 uv0            : TEXCOORD0;
                float2 uv1            : TEXCOORD1;
                float2 uv2            : TEXCOORD2;
                float2 uv3            : TEXCOORD3;
                float2 uv4            : TEXCOORD4;
            };
            
            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);

                half2 pixel;
                pixel.x = _MainTex_TexelSize.x;
                pixel.y = _MainTex_TexelSize.y;
                pixel *= _TexelScale;

                // -1, -1 |   -   | +1, -1
                //    -   | 0,  0 |    -   
                // -1, +1 |   -   | +1, +1
                OUT.uv0 = IN.uv + half2(-pixel.x, -pixel.y);
                OUT.uv1 = IN.uv + half2(-pixel.x, +pixel.y);
                OUT.uv2 = IN.uv;
                OUT.uv3 = IN.uv + half2(-pixel.x, +pixel.y);
                OUT.uv4 = IN.uv + half2(+pixel.x, +pixel.y);

                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                #if IS_BLUR
                    half3 color = half3(0.0, 0.0, 0.0);

                    color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv0).rgb;
                    color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv1).rgb;
                    color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv2).rgb * 4.0;;
                    color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv3).rgb;
                    color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv4).rgb;

                    color /= 8.0;

                    return half4(color, 1);
                #else
                    return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv4);
                #endif
            }
            ENDHLSL
        }
    }
}
