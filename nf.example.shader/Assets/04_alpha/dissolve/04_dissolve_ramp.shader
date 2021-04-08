Shader "example/04_dissolve_ramp"
{
	Properties
	{
		_MainTex("texture", 2D)						= "white" {}
		[NoScaleOffset]_DissolveTex("dissolve", 2D)	= "white" {}
		[NoScaleOffset]_RampTex("Ramp", 2D)			= "white" {}

		_Cutoff("Cutoff", Range(0, 1))				= 0.25
		_EdgeWidth("Edge width", Range(0, 1))		= 0.1
	}

	SubShader
	{
		Tags
		{
			"RenderPipeline" = "UniversalRenderPipeline"
			"Queue" = "AlphaTest"
			"RenderType" = "TransparentCutout"
		}

		Pass
		{
			Tags
			{
				"LightMode" = "UniversalForward"
			}

			HLSLPROGRAM
			#pragma target 3.5

			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			TEXTURE2D(_MainTex);		SAMPLER(sampler_MainTex);
			TEXTURE2D(_DissolveTex);	SAMPLER(sampler_DissolveTex);
			TEXTURE2D(_RampTex);		SAMPLER(sampler_RampTex);

			CBUFFER_START(UnityPerMaterial)
				float4 _MainTex_ST;

				half _Cutoff;
				half _EdgeWidth;
			CBUFFER_END

			struct APPtoVS
			{
				float4 positionOS : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct VStoFS
			{
				float4 positionCS : SV_POSITION;
				float2 uv : TEXCOORD0;
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
				half cutout = SAMPLE_TEXTURE2D(_DissolveTex, sampler_DissolveTex, IN.uv).r;
				clip(cutout - _Cutoff);
				
				half degree = saturate((cutout - _Cutoff)/ _EdgeWidth);
				half4 edgeColor = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, half2(degree, 0));

				half4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);

				return lerp(edgeColor, color, degree);
			}
			ENDHLSL
		}
	}
}
