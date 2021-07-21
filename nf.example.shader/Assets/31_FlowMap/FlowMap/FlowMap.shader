Shader "FlowMap"
{
    Properties
    {
        _MainTex("_MainTex", 2D)		= "white" {}
        _FlowTex("_FlowTex", 2D)		= "white" {}
        _FlowSpeed("_FlowSpeed", Float)	= 5
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
            Name "FLOW_MAP"

            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            #pragma target 3.5

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);	SAMPLER(sampler_MainTex);
            TEXTURE2D(_FlowTex);	SAMPLER(sampler_FlowTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half _FlowSpeed;
            CBUFFER_END

            struct APPtoVS
            {
                float4 positionOS	: POSITION;
                float2 uv			: TEXCOORD0;
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
                half2 flowTex = SAMPLE_TEXTURE2D(_FlowTex, sampler_FlowTex, IN.uv).rg;

                // flowTex[0, 1] => [-1, 1]
                half2 flowUV = flowTex * 2.0 - 1.0;

                // flowTex[0, 1] => [-0.5, 0.5]
                // half2 flowUV = flowTex - 0.5;

                // [-1, 1] 선형 반복.
                half flowLerp = abs((frac(_Time.x * _FlowSpeed) - 0.5) * 2.0);

                half2 uv0 = IN.uv + flowUV * frac(_Time.x * _FlowSpeed);
                half2 uv1 = IN.uv + flowUV * frac(_Time.x * _FlowSpeed + 0.5);

                half3 mainTex0 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv0).rgb;
                half3 mainTex1 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv1).rgb;

                return half4(lerp(mainTex0, mainTex1, flowLerp), 1);
            }
            ENDHLSL
        }
    }
}
