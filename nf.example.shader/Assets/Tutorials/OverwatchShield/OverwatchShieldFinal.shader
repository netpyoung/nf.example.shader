Shader "OverwatchShieldFinal"
{
    // ref:
    // - https://lexdev.net/tutorials/case_studies/overwatch_shield.html
    // - https://github.com/LexdevTutorials/OverwatchShield

    Properties
    {
        // R | HexEdge
        // G | Pulse
        // B | Edge
        _CombinedTex("Combined Texture", 2D) = "white" {}

        _BaseColor("Base Color", Color) = (0, 0.1, 0.1, 1)
        _HexEdgeColor("Hex Edge Color", Color) = (1, 0, 0, 1)
        _EdgeColor("Edge Color", Color) = (0, 0, 0.5, 1)

        // Pulse
        _PulseIntensity("Hex Pulse Intensity", float) = 3.0
        _PulseTimeScale("Hex Pulse Time Scale", float) = 2.0
        _PulsePosScale("Hex Pulse Position Scale", float) = 50.0
        _PulseTexOffsetScale("Hex Pulse Texture Offset Scale", float) = 1.5

        // Hex Edge
        _HexEdgeIntensity("Hex Edge Intensity", float) = 2.0
        _HexEdgeTimeScale("Hex Edge Time Scale", float) = 2.0
        _HexEdgeWidthModifier("Hex Edge Width Modifier", Range(0,1)) = 0.8
        _HexEdgePosScale("Hex Edge Position Scale", float) = 80.0
        
        // Edge
        _EdgeIntensity("Edge Intensity", float) = 10.0
        _EdgeExponent("Edge Falloff Exponent", float) = 6.0

        // Intersection Highlight
        _IntersectIntensity("Intersection Intensity", float) = 10.0
        _IntersectExponent("Intersection Falloff Exponent", float) = 6.0
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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            TEXTURE2D(_CombinedTex);
            SAMPLER(sampler_CombinedTex);

            CBUFFER_START(UnityPerMaterial)
                half4 _CombinedTex_ST;

                half4 _BaseColor;
                half4 _EdgeColor;

                half _PulseIntensity;
                half _PulseTimeScale;
                half _PulsePosScale;
                half _PulseTexOffsetScale;

                half _HexEdgeIntensity;
                half4 _HexEdgeColor;
                half _HexEdgeTimeScale;
                half _HexEdgeWidthModifier;
                half _HexEdgePosScale;

                half _EdgeIntensity;
                half _EdgeExponent;
                half _IntersectIntensity;
                half _IntersectExponent;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float4 positionOS   : TEXCOORD1;
                float3 positionWS   : TEXCOORD2;
                float4 positionNDC  : TEXCOORD3;
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT = (Varyings) 0;

                VertexPositionInputs vertexInputs = GetVertexPositionInputs(IN.positionOS.xyz);

                OUT.positionHCS = vertexInputs.positionCS;
                OUT.uv = TRANSFORM_TEX(IN.uv, _CombinedTex);
                OUT.positionOS = IN.positionOS;
                OUT.positionWS = vertexInputs.positionWS;
                OUT.positionNDC = vertexInputs.positionNDC;

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                
                half3 combinedTex = SAMPLE_TEXTURE2D(_CombinedTex, sampler_CombinedTex, IN.uv).rgb;

                half horizontalDist = abs(IN.positionOS.x);
                half verticalDist = abs(IN.positionOS.z);

                // Pulse
                half4 pulseColor = combinedTex.g;
                half4 pulseTerm = pulseColor * _BaseColor * _PulseIntensity;
                pulseTerm *= abs(
                    sin(_Time.y * _PulseTimeScale               // 시간 빠르기.
                        - horizontalDist * _PulsePosScale       // 좌우 이동.
                        + pulseColor * _PulseTexOffsetScale     // PulseColor에 대한 가중치.
                    )
                );

                // HexEdge
                half hexEdge = combinedTex.r;
                half4 hexEdgeTerm = hexEdge * _HexEdgeColor * _HexEdgeIntensity;
                hexEdgeTerm *= max(
                    sin((horizontalDist + verticalDist) * _HexEdgePosScale
                        - _Time.y * _HexEdgeTimeScale)
                    - _HexEdgeWidthModifier
                    ,
                    0.0f
                );
                hexEdgeTerm *= (1 / (1 - _HexEdgeWidthModifier));

                // Edge
                half edgeTex = combinedTex.b;
                half3 edgeTerm = pow(edgeTex, _EdgeExponent) * _EdgeColor.rgb * _EdgeIntensity;

                // InterSection
                half2 screenUV = IN.positionNDC.xy / IN.positionNDC.w;
                half depth = Linear01Depth(SampleSceneDepth(screenUV), _ZBufferParams) * _ProjectionParams.z - IN.positionNDC.w;
                half intersectGradient = 1 - min(depth, 1.0f);
                half3 intersectTerm = _EdgeColor.rgb * pow(intersectGradient, _IntersectExponent) * _IntersectIntensity;


                half4 finalColor = half4(_BaseColor.rgb + pulseTerm.rgb + hexEdgeTerm.rgb + edgeTerm + intersectTerm, _BaseColor.a);
                return finalColor;
            }
            ENDHLSL
        }
    }
}
