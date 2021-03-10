Shader "VertexColor"
{
	Properties
	{
		[KeywordEnum(RGBA, R, G, B, A)]
		_ColorMode("ColorMode", Float) = 0
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
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			#pragma multi_compile_local _COLORMODE_RGBA _COLORMODE_R _COLORMODE_G _COLORMODE_B _COLORMODE_A

			struct Attributes
			{
				float4 positionOS : POSITION;
				float4 color	  : COLOR;
			};

			struct Varyings
			{
				float4 positionHCS : SV_POSITION;
				float4 color	   : TEXCOORD1;
			};

			Varyings vert(Attributes IN)
			{
				Varyings OUT;
				ZERO_INITIALIZE(Varyings, OUT);

				OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.color = IN.color;
				return OUT;
			}

			half4 frag(Varyings IN) : SV_Target
			{
#if _COLORMODE_RGBA
				return IN.color;
#elif _COLORMODE_R
				return half4(IN.color.r, 0, 0, 1);
#elif _COLORMODE_G
				return half4(0, IN.color.g, 0, 1);
#elif _COLORMODE_B
				return half4(0, 0, IN.color.b, 1);
#elif _COLORMODE_A
				return half4(IN.color.a, IN.color.a, IN.color.a, 1);
#endif
			}
			ENDHLSL
		}
	}
}
