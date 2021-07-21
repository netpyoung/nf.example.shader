Shader "test_property_2d"
{
	Properties
	{
		[HideInInspector]
		_MainTex("texture", 2D) = "gray" {}
		[KeywordEnum(2D, GAMMA, LINEAR)]
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
			Name "TEST_PROPERTY_2D"

			Tags
			{
				"LightMode" = "UniversalForward"
			}

			HLSLPROGRAM
			#pragma target 3.5

			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile_local _COLORMODE_2D _COLORMODE_GAMMA _COLORMODE_LINEAR

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			TEXTURE2D(_MainTex);		SAMPLER(sampler_MainTex);

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
				OUT.uv = IN.uv;

				return OUT;
			}

			half4 frag(VStoFS IN) : SV_Target
			{
#if _COLORMODE_2D
				return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
#elif _COLORMODE_GAMMA
				return pow(half4(0.5, 0.5, 0.5, 1), 2.2);
#elif _COLORMODE_LINEAR
				return half4(0.5, 0.5, 0.5, 1);
#endif
			}
			ENDHLSL
		}
	}
}
