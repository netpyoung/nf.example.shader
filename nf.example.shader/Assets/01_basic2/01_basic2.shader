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
			"Queue" = "Geometry"
			"RenderType" = "Opaque"
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

			CBUFFER_START(UnityPerMaterial)
				// Scriptable Render Pipeline Batcher
				// https://docs.unity3d.com/Manual/SRPBatcher.html

				half4 _BaseColor;
			CBUFFER_END

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

				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				return OUT;
			}

			half4 frag(VStoFS IN) : SV_Target
			{
				return _BaseColor;
			}
			ENDHLSL
		}
	}
}
