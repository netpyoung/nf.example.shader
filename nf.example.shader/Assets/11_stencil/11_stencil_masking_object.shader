Shader "Stencil"
{
	Properties
	{
		_OutlineColor("_OutlineColor", Color) = (1, 1, 1, 1)
	}

	SubShader
	{
		Tags
		{
			"RenderPipeline" = "UniversalRenderPipeline"
			"Queue" = "Transparent"
			"RenderType" = "Transparent"
		}
	
		Pass
		{
			Tags
			{
				"LightMode" = "UniversalForward"
			}
			
			Stencil
			{
				Ref     1
				Comp    Equal
			}

			HLSLPROGRAM
			#pragma target 3.5

			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


			CBUFFER_START(UnityPerMaterial)
				float4 _OutlineColor;
			CBUFFER_END

			struct APPtoVS
			{
				float4 positionOS	: POSITION;
			};

			struct VStoFS
			{
				float4 positionCS	: SV_POSITION;
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
				return _OutlineColor;
			}
			ENDHLSL
		}
	}
}
