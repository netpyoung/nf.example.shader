Shader "example/04_dissolve_ramp"
{
	Properties
	{
		_MainTex("texture", 2D) = "white" {}
		[NoScaleOffset]_DissolveTex("dissolve", 2D) = "white" {}
		[NoScaleOffset]_RampTex("Ramp", 2D) = "white" {}

		_Amount("Amount", Range(0, 1)) = 0
		_EdgeWidth("Edge width", Range(0, 1)) = 0.1
	}

	SubShader
	{
		Pass
		{
			Tags
			{
				"RenderPipeline" = "UniversalRenderPipeline"
				"LightMode" = "UniversalForward"
				"RenderType" = "Opaque"
			}

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			struct Attributes
			{
				float4 positionOS : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct Varyings
			{
				float4 positionHCS : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			TEXTURE2D(_MainTex);		SAMPLER(sampler_MainTex);
			TEXTURE2D(_DissolveTex);	SAMPLER(sampler_DissolveTex);
			TEXTURE2D(_RampTex);		SAMPLER(sampler_RampTex);

			CBUFFER_START(UnityPerMaterial)
				float4 _MainTex_ST;

				half _Amount;
				half _EdgeWidth;
			CBUFFER_END

			Varyings vert(Attributes IN)
			{
				Varyings OUT;
				ZERO_INITIALIZE(Varyings, OUT);

				OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

				return OUT;
			}

			half4 frag(Varyings IN) : SV_Target
			{
				half cutout = SAMPLE_TEXTURE2D(_DissolveTex, sampler_DissolveTex, IN.uv).r;
				clip(cutout - _Amount);
				
				half degree = saturate((cutout - _Amount)/ _EdgeWidth);
				half4 edgeColor = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, half2(degree, 0));

				half4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);

				return lerp(edgeColor, color, degree);
			}
			ENDHLSL
		}
	}
}