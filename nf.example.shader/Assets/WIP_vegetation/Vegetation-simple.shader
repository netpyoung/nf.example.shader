Shader "Vegetation-simple"
{
	Properties
	{
		_AlbedoTex("texture", 2D) = "white" {}
		[Normal][NoScaleOffset]_NormalTex("texture", 2D) = "bump" {}
		[NoScaleOffset]_MaskTex("texture", 2D) = "white" {}

		_WindTurbulence("Wind Turbulence", Float) = 1
		_WindStrength("Wind Strength", Float) = 1
	}

	SubShader
	{
		Pass
		{
			Tags
			{
				"RenderType" = "Opaque"
				"RenderPipeline" = "UniversalRenderPipeline"
			}

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


			TEXTURE2D(_AlbedoTex);		SAMPLER(sampler_AlbedoTex);
			TEXTURE2D(_NormalTex);		SAMPLER(sampler_NormalTex);
			TEXTURE2D(_MaskTex);		SAMPLER(sampler_MaskTex);

			CBUFFER_START(UnityPerMaterial)
				float4 _AlbedoTex_ST;

				half _WindTurbulence;
				half _WindStrength;
			CBUFFER_END

			struct APPtoVS
			{
				float4 positionOS	: POSITION;
				float4 color		: COLOR;
				float2 uv			: TEXCOORD0;

			};

			struct VStoFS
			{
				float4 positionCS : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			inline half Remap(half In, half2 InMinMax, half2 OutMinMax)
			{
				return OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
			}

			VStoFS vert(APPtoVS IN)
			{
				VStoFS OUT;
				ZERO_INITIALIZE(VStoFS, OUT);

				half amount1 = sin(_Time.y * _WindTurbulence) * 0.1;
				amount1 = lerp(0.1, amount1, min(amount1, 1));
				amount1 *= _WindStrength;
				half amount2 = Remap(_WindStrength * _SinTime.w, half2(-1, 1), half2(-0.1, 0.1));

				IN.positionOS.x += IN.color.r * (amount1 + amount2);

				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv = TRANSFORM_TEX(IN.uv, _AlbedoTex);

				return OUT;
			}

			half4 frag(VStoFS IN) : SV_Target
			{
				// r : metalic
				// g : occlusion
				// b : x
				// a : smoothness
				// SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, IN.uv);
				return SAMPLE_TEXTURE2D(_AlbedoTex, sampler_AlbedoTex, IN.uv);
			}
			ENDHLSL
		}
	}
}
