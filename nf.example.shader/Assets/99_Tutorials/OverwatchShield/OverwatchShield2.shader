Shader "OverwatchShield2"
{
    // ref:
    // - https://lexdev.net/tutorials/case_studies/overwatch_shield.html
    // - https://github.com/LexdevTutorials/OverwatchShield

    Properties
    {
        _HexEdgeTex("Hex Edge Texture", 2D) = "white" {}

        _HexEdgeIntensity("Hex Edge Intensity", float) = 2.0
        _HexEdgeColor("Hex Edge Color", Color) = (1, 1, 1, 1)
        _HexEdgeTimeScale("Hex Edge Time Scale", float) = 2.0
        _HexEdgeWidthModifier("Hex Edge Width Modifier", Range(0,1)) = 0.8
        _HexEdgePosScale("Hex Edge Position Scale", float) = 80.0
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Transparent"

            // RenderType is optional but used in https://docs.unity3d.com/Manual/SL-ShaderReplacement.html
            "RenderType" = "Transparent"
        }
        
        Pass
        {
            Cull Off
            Blend SrcAlpha One

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_HexEdgeTex);
            SAMPLER(sampler_HexEdgeTex);

            CBUFFER_START(UnityPerMaterial)
                half4 _HexEdgeTex_ST;

                half _HexEdgeIntensity;
                half4 _HexEdgeColor;
                half _HexEdgeTimeScale;
                half _HexEdgeWidthModifier;
                half _HexEdgePosScale;
            CBUFFER_END

            struct APPtoVS
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct VStoFS
            {
                float4 positionCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float4 positionOS   : TEXCOORD1;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT = (VStoFS) 0;

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _HexEdgeTex);
                OUT.positionOS = IN.positionOS;

                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                
                half hexEdge = SAMPLE_TEXTURE2D(_HexEdgeTex, sampler_HexEdgeTex, IN.uv).r;

                half horizontalDist = abs(IN.positionOS.x);
                half verticalDist = abs(IN.positionOS.z);
                half4 hexEdgeTerm = hexEdge * _HexEdgeColor * _HexEdgeIntensity;
                hexEdgeTerm *= max(
                    sin((horizontalDist + verticalDist) * _HexEdgePosScale
                        - _Time.y * _HexEdgeTimeScale)
                    - _HexEdgeWidthModifier
                    ,
                    0.0f
                );
                hexEdgeTerm *= (1 / (1 - _HexEdgeWidthModifier));

                half4 finalColor = half4(hexEdgeTerm.rgb, 1);
                return finalColor;
            }
            ENDHLSL
        }
    }
}
