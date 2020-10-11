Shader "example/01_basic2"
{
	Properties
	{
		_BaseColor("Base Color", Color) = (1, 1, 1, 1)
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
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			#pragma vertex vert
			#pragma fragment frag

			struct Attributes
			{
				float4 positionOS : POSITION;
			};

			struct Varyings
			{
				float4 positionHCS : SV_POSITION;
			};

			CBUFFER_START(UnityPerMaterial)
				// Scriptable Render Pipeline Batcher
				// https://docs.unity3d.com/Manual/SRPBatcher.html

				half4 _BaseColor;
			CBUFFER_END

			Varyings vert(Attributes IN)
			{
				Varyings OUT;
				// o.positionCS = mul(UNITY_MATRIX_MVP, v.positionOS);
				// Use of UNITY_MATRIX_MVP is detected. To transform a vertex into clip space, consider using UnityObjectToClipPos for better performance and to avoid z-fighting issues with the default depth pass and shadow caster pass.

				OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
				// HClip: Homogeneous Clip

				return OUT;
			}

			half4 frag(Varyings IN) : SV_Target
			{
				return _BaseColor;
			}
			ENDHLSL
		}
	}
}
