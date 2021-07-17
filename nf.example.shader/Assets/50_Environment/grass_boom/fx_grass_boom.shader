Shader "fx_grass_boom"
{
	Properties
	{
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

			Cull Back
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			struct APPtoVS
			{
				float4 positionOS	: POSITION;
				float2 uv			: TEXCOORD0;
				float4 color		: COLOR;
			};

			struct VStoFS
			{
				float4 positionCS	: SV_POSITION;
				float2 uv			: TEXCOORD0;
				float4 color		: TEXCOORD1;
			};

			half SphereMask(in half2 coords, in half2 center, in half radius, in half hardness)
			{
				return 1 - saturate((distance(coords, center) - radius) / (1 - hardness));
			}

			VStoFS vert(APPtoVS IN)
			{
				VStoFS OUT;
				ZERO_INITIALIZE(VStoFS, OUT);

				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv = IN.uv;
				OUT.color = IN.color;

				return OUT;
			}

			half4 frag(VStoFS IN) : SV_Target
			{
				half2 rg = normalize(IN.uv - 0.5) * 0.5 + 0.5;
				half sphereMask = SphereMask(IN.uv, 0.5, 0.1, 0.6);
				return half4(rg, 0, sphereMask * IN.color.a);
			}
			ENDHLSL
		}
	}
}
