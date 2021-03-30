Shader "example/02_texture"
{
	Properties
	{
		_MainTex("texture", 2D) = "white"
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

			TEXTURE2D(_MainTex);	SAMPLER(sampler_MainTex);

			CBUFFER_START(UnityPerMaterial)
				float4 _MainTex_ST;
			CBUFFER_END

			struct Attributes
			{
				float4 positionOS	: POSITION;
				float2 uv			: TEXCOORD0;
			};

			struct Varyings
			{
				float4 positionCS	: SV_POSITION;
				float2 uv			: TEXCOORD0;
			};
			
			Varyings vert(Attributes IN)
			{
				Varyings OUT;
				ZERO_INITIALIZE(Varyings, OUT);

				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

				return OUT;
			}

			half4 frag(Varyings IN) : SV_Target
			{
				return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
			}
			ENDHLSL
		}
	}
}
