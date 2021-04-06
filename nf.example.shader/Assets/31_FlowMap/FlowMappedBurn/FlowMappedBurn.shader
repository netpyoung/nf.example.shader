Shader "FlowMappedBurn"
{
	Properties
	{
		_MainTex("texture", 2D) = "white" {}
		_FlowTex("_FlowTex", 2D) = "white" {}
		_NoiseTex("_NoiseTex", 2D) = "white" {}
		_FlowDirection("_FlowDirection(x, y)", Vector) = (1, 0, 0, 0)

		_FlowMapTiling("_FlowMapTiling", Float) = 1
		_NoiseTiling("_NoiseTiling", Float) = 1
		_MaskRadius("_MaskRadius", Float) = 0.2
		_MaskHardness("_MaskHardness", Float) = 0.7
		_EmberSpread("_EmberSpread", Float) = 0.1

		[HDR] _EmberColor("_Ember", Color) = (1, 1, 1, 1)
		_BaseColor("_BaseColor", Color) = (1, 1, 1, 1)
		_CharringSpread("_CharringSpread", Float) = 0.4
		_InteractPosition("_InteractPosition(x, y, z)", Vector) = (0, 0, 0, 0)
		_DistortionStrength("_DistortionStrength", Float) = 0.5
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
			Name "FLOW_MAPPED_BURN"

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
			TEXTURE2D(_NoiseTex);	SAMPLER(sampler_NoiseTex);
			

			CBUFFER_START(UnityPerMaterial)
				float4 _MainTex_ST;
				half _FlowMapTiling;
				half _NoiseTiling;
				half2 _FlowDirection;
				half _MaskRadius;
				half _MaskHardness;
				half _EmberSpread;
				half _CharringSpread;
				half4 _EmberColor;
				half4 _BaseColor;
				half3 _InteractPosition;
				half _DistortionStrength;
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
				half3 positionWS	: TEXCOORD1;
			};

			VStoFS vert(in APPtoVS IN)
			{
				VStoFS OUT;
				ZERO_INITIALIZE(VStoFS, OUT);

				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
				OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);

				return OUT;
			}
			
			half SphereMask(half3 p, half3 center, half radius, half hardness)
			{
				return 1 - saturate((distance(p, center) - radius) / (1 - hardness));
			}

			half4 frag(in VStoFS IN) : SV_Target
			{
				half2 flowTex = SAMPLE_TEXTURE2D(_FlowTex, sampler_FlowTex, IN.uv * _FlowMapTiling).rg;
				half2 dired = flowTex * _FlowDirection;

				half time = _Time.y * 0.5;

				half2 noiseUV = IN.uv * _NoiseTiling;

				half2 noiseUV0 = noiseUV + frac(time) * _DistortionStrength * dired;
				half2 noiseUV1 = noiseUV + frac(time + 0.5) * _DistortionStrength * dired;
				half noiseTex0 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, noiseUV0).r;
				half noiseTex1 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, noiseUV1).r;

				half noiseAlpha = abs(frac(time) * 2 - 1);
				half noise = lerp(noiseTex0, noiseTex1, noiseAlpha);
				// return noise;

				half sphereMask = (1 - SphereMask(IN.positionWS, _InteractPosition, _MaskRadius, _MaskHardness)) * 2;
				// return sphereMask;

				half noisedMask = saturate(sphereMask - noise);
				// return noisedMask;
				clip(noisedMask - 0.3);

				half emberGlow = saturate(1 - (distance(noisedMask, 0.45) / _EmberSpread));
				// return emberGlow;
				half charring = saturate((distance(noisedMask, 0.5) / _CharringSpread) - 0.25);
				// return charring;

				half3 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;
				return half4(charring * _BaseColor * mainTex + pow(emberGlow * _EmberColor * 2, 2), noisedMask);
			}
			ENDHLSL
		}
	}
}
