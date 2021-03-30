Shader "example/01_basic2"
{
	Properties
	{
		_BaseColor("Base Color", Color) = (1, 1, 1, 1)
	}

	SubShader
	{
		Tags
		{
			"RenderPipeline" = "UniversalRenderPipeline"
		}

		Pass
		{
			Tags
			{
				"LightMode" = "UniversalForward"
				"Queue" = "Geometry"
				"RenderType" = "Opaque"
			}

			HLSLPROGRAM
			#pragma target 3.5

			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			CBUFFER_START(UnityPerMaterial)
				// Scriptable Render Pipeline Batcher
				// https://docs.unity3d.com/Manual/SRPBatcher.html

				half4 _BaseColor;
			CBUFFER_END

			struct Attributes
			{
				float4 positionOS : POSITION;
			};

			struct Varyings
			{
				float4 positionCS : SV_POSITION;
			};

			Varyings vert(Attributes IN)
			{
				Varyings OUT;
				ZERO_INITIALIZE(Varyings, OUT);

				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
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
