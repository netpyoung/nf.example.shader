Shader "07_vertex_color"
{
    Properties
    {
        [KeywordEnum(RGBA, R, G, B, A)]
        _ColorMode("ColorMode", Float) = 0
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
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            #pragma multi_compile_local _COLORMODE_RGBA _COLORMODE_R _COLORMODE_G _COLORMODE_B _COLORMODE_A

            struct APPtoVS
            {
                float4 positionOS : POSITION;
                float4 color      : COLOR;
            };

            struct VStoFS
            {
                float4 positionCS : SV_POSITION;
                float4 color       : TEXCOORD1;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.color = IN.color;
                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                #if _COLORMODE_RGBA
                    return IN.color;
                #elif _COLORMODE_R
                    return half4(IN.color.r, 0, 0, 1);
                #elif _COLORMODE_G
                    return half4(0, IN.color.g, 0, 1);
                #elif _COLORMODE_B
                    return half4(0, 0, IN.color.b, 1);
                #elif _COLORMODE_A
                    return half4(IN.color.a, IN.color.a, IN.color.a, 1);
                #endif
            }
            ENDHLSL
        }
    }
}
