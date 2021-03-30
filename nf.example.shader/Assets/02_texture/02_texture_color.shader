Shader "example/02_texture_color"
{
	Properties
	{
		_MainTex("texture", 2D) = "white"

		[KeywordEnum(RGBA, R, G, B, A)]
		_ColorMode("ColorMode", Float) = 0
	}

	SubShader
	{
		Tags
		{
			"RenderPipeline" = "UniversalRenderPipeline"
		}

		Pass
		{
			Name "TEXTURE_COLOR"

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

			#pragma multi_compile_local _COLORMODE_RGBA _COLORMODE_R _COLORMODE_G _COLORMODE_B _COLORMODE_A

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			TEXTURE2D(_MainTex);	SAMPLER(sampler_MainTex);

			CBUFFER_START(UnityPerMaterial)
				float4 _MainTex_ST;
			CBUFFER_END

			struct APPtoVS
			{
				float4 positionOS	: POSITION;
				float2 uv			: TEXCOORD0;
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
#if _COLORMODE_R
				half r = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).r;
				return half4(r, 0, 0, 1);
#elif _COLORMODE_G
				half g = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).g;
				return half4(0, g, 0, 1);
#elif _COLORMODE_B
				half b = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).b;
				return half4(0, 0, b, 1);
#elif _COLORMODE_A
				half a = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).a;
				return half4(a, a, a, 1);
#else
				return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
#endif
			}
			ENDHLSL
		}
	}
}
