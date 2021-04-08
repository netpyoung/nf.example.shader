Shader "alpha_blending"
{
	Properties
	{
		_MainTex("Main Texture", 2D) = "white" {}
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
			Name "ALPHA_BLENDING"

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
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			TEXTURE2D(_MainTex);		SAMPLER(sampler_MainTex);

			CBUFFER_START(UnityPerMaterial)
				float4 _MainTex_ST;
			CBUFFER_END

			struct APPtoVS
			{
				float4 positionOS	: POSITION;
				float4 uv			: TEXCOORD0;
			};

			struct VStoFS
			{
				float4 positionCS	: SV_POSITION;
				float2 uv			: TEXCOORD0;
			};

			VStoFS vert(APPtoVS IN)
			{
				VStoFS OUT;
				ZERO_INITIALIZE(VStoFS, OUT);

				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

				return OUT;
			}

			half4 frag(VStoFS IN) : SV_Target
			{
				return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
			}
			ENDHLSL
		}
	}
}
