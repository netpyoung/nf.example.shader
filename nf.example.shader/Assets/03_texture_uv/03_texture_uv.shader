Shader "example/03_texture_uv"
{
	Properties
	{
		_Texture("texture", 2D) = "white"
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

			TEXTURE2D(_Texture);		SAMPLER(sampler_Texture);

			CBUFFER_START(UnityPerMaterial)
				float4 _Texture_ST;
			CBUFFER_END

			Varyings vert(Attributes IN)
			{
				Varyings OUT;
				ZERO_INITIALIZE(Varyings, OUT);

				OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv = TRANSFORM_TEX(IN.uv, _Texture);

				// Time : https://docs.unity3d.com/Manual/SL-UnityShaderVariables.html
				OUT.uv += frac(float2(0, 1) * _Time.x);

				return OUT;
			}

			half4 frag(Varyings IN) : SV_Target
			{
				return SAMPLE_TEXTURE2D(_Texture, sampler_Texture, IN.uv);
			}
			ENDHLSL
		}
	}
}
