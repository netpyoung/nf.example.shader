Shader "dissolve_character"
{
	Properties
	{
		_SplitValue("Split Value", Range(0, 1)) = 1
		[HDR]_GlowColor("Glow Color", Color) = (1, 1, 1, 1)
		_GlowWidth("Glow Width", Float) = 1

		_Height("Height", Float) = 2

		[Toggle(IS_NOISE)]_IsNoise("Noise Tex?", Float) = 0
		[NoScaleOffset]_NoiseTex("Noise Texture", 2D) = "white" {}
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
				"RenderType" = "Transparent"
				"Queue" = "Transparent"
			}

			HLSLPROGRAM
			#pragma target 3.5
			#pragma shader_feature_local _ IS_NOISE

			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			TEXTURE2D(_NoiseTex); SAMPLER(sampler_NoiseTex);

			CBUFFER_START(UnityPerMaterial)
				half _SplitValue;
				half _Height;
				half _GlowWidth;
				half3 _GlowColor;
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
				float3 positionWS	: TEXCOORD1;
			};

			Varyings vert(Attributes IN)
			{
				Varyings OUT;
				ZERO_INITIALIZE(Varyings, OUT);

				
				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
				OUT.uv = IN.uv;
				return OUT;
			}

			half4 frag(Varyings IN) : SV_Target
			{
#if IS_NOISE
				half split = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, IN.uv).r;
#else
				half split = IN.positionWS.y / _Height;
#endif

				// step(edge, x) => (edge < x) ? 0.0 : 1
				half alpha = step(split, _SplitValue);
				clip(alpha - 0.5);

				half3 glow = _GlowColor.rgb * (1 - step(split, _SplitValue - _GlowWidth));

				half3 baseColor = half3(1, 0, 0);

				return half4(baseColor + glow, 0);
			}
			ENDHLSL
		}
	}
}
