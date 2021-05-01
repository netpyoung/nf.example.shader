Shader "Tone/ACES"
{
	// ref: https://github.com/TheRealMJP/BakingLab/blob/master/BakingLab/ACES.hlsl

	Properties
	{
		_MainTex("texture", 2D) = "white" {}

		[KeywordEnum(None, Fitted, Slim)]_ACES("ACE Mode", Float) = 0
		_Exposure("_Exposure", Range(0.01, 5.0)) = 1
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
			Name "TONE_ACES"

			Tags
			{
				"LightMode" = "UniversalForward"
			}

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma shader_feature_local _ _ACES_FITTED _ACES_SLIM

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			TEXTURE2D(_MainTex);		SAMPLER(sampler_MainTex);

			CBUFFER_START(UnityPerMaterial)
				float4 _MainTex_ST;
				float _Exposure;
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


			// sRGB => XYZ => D65_2_D60 => AP1 => RRT_SAT
			static const float3x3 ACESInputMat =
			{
				{0.59719, 0.35458, 0.04823},
				{0.07600, 0.90834, 0.01566},
				{0.02840, 0.13383, 0.83777}
			};

			// ODT_SAT => XYZ => D60_2_D65 => sRGB
			static const float3x3 ACESOutputMat =
			{
				{ 1.60475, -0.53108, -0.07367},
				{-0.10208,  1.10813, -0.00605},
				{-0.00327, -0.07276,  1.07602}
			};

			float3 RRTAndODTFit(float3 v)
			{
				float3 a = v * (v + 0.0245786f) - 0.000090537f;
				float3 b = v * (0.983729f * v + 0.4329510f) + 0.238081f;
				return a / b;
			}

			float3 ACES_Fitted(float3 color)
			{
				color = mul(ACESInputMat, color);

				// Apply RRT and ODT
				color = RRTAndODTFit(color);

				color = mul(ACESOutputMat, color);

				// Clamp to [0, 1]
				color = saturate(color);

				return color;
			}


			float3 ACES_Slim(float3 x)
			{
				// ref: https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/

				x *= 0.6;
				const float a = 2.51f;
				const float b = 0.03f;
				const float c = 2.43f;
				const float d = 0.59f;
				const float e = 0.14f;
				return saturate((x * (a * x + b)) / (x * (c * x + d) + e));
			}

			float3 unreal(float3 x)
			{
				return x / (x + 0.155) * 1.019;
			}

			half4 frag(VStoFS IN) : SV_Target
			{
				half3 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;
#if _ACES_FITTED
				half3 color = ACES_Fitted(mainTex * _Exposure);
				return half4(color, 1);
#elif _ACES_SLIM
				half3 color = ACES_Slim(mainTex * _Exposure);
				return half4(color, 1);
#else
				return half4(mainTex * _Exposure, 1);
#endif
			}
			ENDHLSL
		}
	}
}
