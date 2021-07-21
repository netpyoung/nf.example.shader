Shader "ShadowCasterOnly"
{
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Geometry"
            "RenderType" = "Opaque"
        }

        Pass
        {
            Name "SHADOW_CASTER_ONLY"

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

            struct APPtoVS
            {
                float4 positionOS   : POSITION;
                float4 normal       : NORMAL;
            };

            struct VStoFS
            {
                float4 positionCS  : SV_POSITION;
            };

            VStoFS shadowVert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                half3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                half3 N = TransformObjectToWorldNormal(IN.normal.xyz);
                OUT.positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, N, _MainLightPosition.xyz));

                return OUT;
            }

            half4 shadowFrag(VStoFS IN) : SV_Target
            {
                return 0;
            }
            ENDHLSL
        }
    }
}
