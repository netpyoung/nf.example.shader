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
			Name "RED_CIRCLE"

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

			struct APPtoVS
			{
				float4 positionOS : POSITION;
			};

			struct VStoFS
			{
				float4 positionCS : SV_POSITION;
			};

			VStoFS vert(APPtoVS IN)
			{
				VStoFS OUT;
				ZERO_INITIALIZE(VStoFS, OUT);

				// o.positionCS = mul(UNITY_MATRIX_MVP, v.positionOS);
				// Use of UNITY_MATRIX_MVP is detected. To transform a vertex into clip space, consider using UnityObjectToClipPos for better performance and to avoid z-fighting issues with the default depth pass and shadow caster pass.
				// HClip: Homogeneous Clip
				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				return OUT;
			}

			half4 frag(VStoFS IN) : SV_Target
			{
				return half4(1, 0, 0, 1);
			}
			ENDHLSL
		}
	}
}
