Shader "example/00_basic"
{
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

			struct Attributes
			{
				float4 positionOS : POSITION;
			};

			struct Varyings
			{
				float4 positionHCS : SV_POSITION;
			};

			Varyings vert(Attributes IN)
			{
				Varyings OUT;
				ZERO_INITIALIZE(Varyings, OUT);

				// o.positionCS = mul(UNITY_MATRIX_MVP, v.positionOS);
				// Use of UNITY_MATRIX_MVP is detected. To transform a vertex into clip space, consider using UnityObjectToClipPos for better performance and to avoid z-fighting issues with the default depth pass and shadow caster pass.
				// HClip: Homogeneous Clip
				OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
				return OUT;
			}

			half4 frag(Varyings IN) : SV_Target
			{
				return half4(1, 0, 0, 1);
			}
			ENDHLSL
		}
	}
}
