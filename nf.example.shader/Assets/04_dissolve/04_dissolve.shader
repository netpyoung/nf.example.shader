Shader "example/04_dissolve"
{
	Properties
	{
		_Texture("texture", 2D) = "white" {}
		_TexDissolve("dissolve", 2D) = "white" {}
		_Amount("Amount", Range(0, 1)) = 0
		_EdgeColor1("Edge colour 1", Color) = (1.0, 1.0, 1.0, 1.0)
		_EdgeColor2("Edge colour 2", Color) = (1.0, 1.0, 1.0, 1.0)
		_DissolveLevel("Dissolution level", Range(0, 1)) = 0.1
		_EdgeWidth("Edge width", Range(0, 1)) = 0.1
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
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


			TEXTURE2D(_Texture);		SAMPLER(sampler_Texture);
			TEXTURE2D(_TexDissolve);	SAMPLER(sampler_TexDissolve);

			CBUFFER_START(UnityPerMaterial)
				float4 _Texture_ST;
				float4 _TexDissolve_ST;

				half _Amount;
				half _DissolveLevel;
				half _EdgeWidth;
				half4 _EdgeColor1;
				half4 _EdgeColor2;
			CBUFFER_END

			struct Attributes
			{
				float4 positionOS : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct Varyings
			{
				float4 positionHCS : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			Varyings vert(Attributes IN)
			{
				Varyings OUT;
				ZERO_INITIALIZE(Varyings, OUT);

				OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv = TRANSFORM_TEX(IN.uv, _Texture);

				return OUT;
			}

			half4 frag(Varyings IN) : SV_Target
			{
				half cutout = SAMPLE_TEXTURE2D(_TexDissolve, sampler_TexDissolve, IN.uv).r;
				clip(cutout - _Amount);
				
				half4 color = SAMPLE_TEXTURE2D(_Texture, sampler_Texture, IN.uv);
				if (cutout < color.a && cutout < _DissolveLevel + _EdgeWidth)
				{
					color = lerp(_EdgeColor1, _EdgeColor2, (cutout - _DissolveLevel) / _EdgeWidth);
				}
					
				return color;
			}
			ENDHLSL
		}
	}
}
