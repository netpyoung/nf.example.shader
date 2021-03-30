Shader "OverwatchShield3"
{
    // ref:
    // - https://lexdev.net/tutorials/case_studies/overwatch_shield.html
    // - https://github.com/LexdevTutorials/OverwatchShield

    Properties
    {
        _Color("Color", Color) = (1, 1, 1, 1)

        _EdgeTex("Edge Texture", 2D) = "white" {}
        _EdgeIntensity("Edge Intensity", float) = 10.0
        _EdgeExponent("Edge Falloff Exponent", float) = 6.0

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

            TEXTURE2D(_EdgeTex);
            SAMPLER(sampler_EdgeTex);

            CBUFFER_START(UnityPerMaterial)
                half4 _Color;

                half4 _EdgeTex_ST;
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
                float4 positionCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float4 positionOS   : TEXCOORD1;
                float3 positionWS   : TEXCOORD2;
                float4 positionNDC  : TEXCOORD3;
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT = (Varyings) 0;

                VertexPositionInputs vertexInputs = GetVertexPositionInputs(IN.positionOS.xyz);

                OUT.positionCS = vertexInputs.positionCS;
                OUT.uv = TRANSFORM_TEX(IN.uv, _EdgeTex);
                OUT.positionOS = IN.positionOS;
                OUT.positionWS = vertexInputs.positionWS;
                OUT.positionNDC = vertexInputs.positionNDC;

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                
                half edgeTex = SAMPLE_TEXTURE2D(_EdgeTex, sampler_EdgeTex, IN.uv).a;
                half3 edgeTerm = pow(edgeTex, _EdgeExponent) * _Color.rgb * _EdgeIntensity;

                half2 screenUV = IN.positionNDC.xy / IN.positionNDC.w;

                half sceneZ = LinearEyeDepth(SampleSceneDepth(screenUV), _ZBufferParams);
                half partZ = IN.positionNDC.w;
                half depth = sceneZ - partZ;

                half intersectGradient = 1 - min(depth, 1.0f);
                half3 intersectTerm = _Color * pow(intersectGradient, _IntersectExponent) * _IntersectIntensity;

                half4 finalColor = half4(intersectTerm, _Color.a);
                return finalColor;
            }
            ENDHLSL
        }
    }
}
