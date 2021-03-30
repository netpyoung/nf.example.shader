Shader "ShadowCasterOnly"
{
    Properties
    {
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
        }

        Pass
        {
            Name "ShadowCaster"

            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            ZWrite On
            Cull Back

            HLSLPROGRAM
            #pragma target 3.5

            #pragma vertex shadowVert
            #pragma fragment shadowFrag

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float4 normal       : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS  : SV_POSITION;
            };

            Varyings shadowVert(Attributes IN)
            {
                Varyings OUT;
                ZERO_INITIALIZE(Varyings, OUT);

                half3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                half3 N = TransformObjectToWorldNormal(IN.normal.xyz);
                OUT.positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, N, _MainLightPosition.xyz));

                return OUT;
            }

            half4 shadowFrag(Varyings IN) : SV_Target
            {
                return 0;
            }
            ENDHLSL
        }
    }
}
