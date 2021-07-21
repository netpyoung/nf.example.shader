Shader "alpha_blending_2pass"
{
    Properties
    {
        _MainTex("Main Texture", 2D) = "white" {}
        _Alpha("Alpha", Range(0, 1)) = 0.5
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalRenderPipeline"
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
        }

        Pass
        {
            Name "ALPHA_BLENDING_2PASS_BACK"

            Tags
            {
                "LightMode" = "SRPDefaultUnlit"
            }

            Cull Front
            ZWrite On
            ColorMask 0

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            CBUFFER_END

            struct APPtoVS
            {
                float4 positionOS	: POSITION;
                float2 uv			: TEXCOORD0;
            };

            struct VStoFS
            {
                float4 positionCS : SV_POSITION;
                float2 uv			: TEXCOORD0;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);

                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                return 0;
            }
            ENDHLSL
        }

        Pass
        {
            Name "ALPHA_BLENDING_2PASS_BACK"

            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Cull Back
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma target 3.5

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D(_MainTex);		SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half _Alpha;
            CBUFFER_END

            struct APPtoVS
            {
                float4 positionOS	: POSITION;
                float4 uv			: TEXCOORD0;
            };

            struct VStoFS
            {
                float4 positionCS	: SV_POSITION;
                float2 uv			: TEXCOORD0;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                half3 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;
                return half4(mainTex, _Alpha);
            }
            ENDHLSL
        }
    }
}
