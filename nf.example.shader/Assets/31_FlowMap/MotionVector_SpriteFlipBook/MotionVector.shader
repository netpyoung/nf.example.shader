Shader "MotionVector"
{
	Properties
	{
		[NoScaleOffset] _MainTex("_MainTex", 2D)			= "white" {}
		[NoScaleOffset] _FlowTex("_FlowTex", 2D)			= "white" {}
		_DistortionStrength("_DistortionStrength", Float)	= 0.0037

		_CutOff("Alpha Cutoff", Range(0, 1))				= 0.15
		_ColumnsX("Columns (X)", Int)						= 8
		_RowsY("Rows (Y)", Int)								= 8

		_FramesPerSeconds("_FramesPerSeconds", Float)		= 3
	}

	SubShader
	{
		Tags
		{
			"RenderPipeline" = "UniversalRenderPipeline"
			"RenderType" = "Transparent"
			"Queue" = "Transparent"
		}

		Pass
		{
			Name "MOTION_VECTOR"

			Tags
			{
				"LightMode" = "UniversalForward"
			}

			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite Off
			Cull Back

			HLSLPROGRAM
			#pragma target 3.5

			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			TEXTURE2D(_MainTex);	SAMPLER(sampler_MainTex);
			TEXTURE2D(_FlowTex);	SAMPLER(sampler_FlowTex);

			CBUFFER_START(UnityPerMaterial)
				half _DistortionStrength;
				half _CutOff;
				uint _ColumnsX;
				uint _RowsY;
				half _FramesPerSeconds;
			CBUFFER_END

			struct APPtoVS
			{
				float4 positionOS	: POSITION;
				float2 uv			: TEXCOORD0;
			};

			struct VStoFS
			{
				float4 positionCS	: SV_POSITION;
				float2 subUV0		: TEXCOORD0;
				float2 subUV1		: TEXCOORD1;
				float frameNumber	: TEXCOORD2;
			};

			half2 GetSubUV(in half2 uv, in half frame, in uint2 imageCount)
			{
				half2 scale = 1.0 / imageCount;

				half index = floor(frame);
				half2 offset = half2(
					fmod(index, imageCount.x),
					-1 - floor(index * scale.x)
				);
				return (uv + offset) * scale;
			}

			VStoFS vert(in APPtoVS IN)
			{
				VStoFS OUT;
				ZERO_INITIALIZE(VStoFS, OUT);

				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);

				half frameNumber = _Time.y * _FramesPerSeconds;
				uint2 imageCount = uint2(_ColumnsX, _RowsY);

				OUT.frameNumber = frameNumber;
				OUT.subUV0 = GetSubUV(IN.uv, frameNumber, imageCount);
				OUT.subUV1 = GetSubUV(IN.uv, frameNumber + 1, imageCount);

				return OUT;
			}

			half4 frag(in VStoFS IN) : SV_Target
			{
				// flowTex[0, 1] => [-1, 1]
				half2 flowTex0 = SAMPLE_TEXTURE2D(_FlowTex, sampler_FlowTex, IN.subUV0).rg;
				half2 flowTex1 = SAMPLE_TEXTURE2D(_FlowTex, sampler_FlowTex, IN.subUV1).rg;
				flowTex0 = flowTex0 * 2.0 - 1.0;
				flowTex1 = flowTex1 * 2.0 - 1.0;

				half interval = frac(IN.frameNumber);
				half2 mainUV0 = IN.subUV0 - (flowTex0 * interval * _DistortionStrength);
				half2 mainUV1 = IN.subUV1 + (flowTex1 * (1 - interval) * _DistortionStrength);
				half4 mainTex0 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, mainUV0);
				half4 mainTex1 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, mainUV1);

				half4 finalColor = lerp(mainTex0, mainTex1, interval);
				clip(finalColor.a - _CutOff);
				return finalColor;
			}
			ENDHLSL
		}
	}
}
