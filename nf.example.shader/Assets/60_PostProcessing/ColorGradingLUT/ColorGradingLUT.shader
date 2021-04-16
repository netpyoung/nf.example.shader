Shader "color_grading_lut"
{
	Properties
	{
		_MainTex("texture", 2D) = "white" {}
		[NoScaleOffset] _LutTex("_LutTex", 2D) = "" {}
		_Lerp("_Lerp", Range(0.0, 1.0)) = 0.5
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
			Name "COLOR_GRADING_LUT"

			Tags
			{
				"LightMode" = "UniversalForward"
			}

			HLSLPROGRAM
			#pragma target 3.5

			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			TEXTURE2D(_MainTex);	SAMPLER(sampler_MainTex);
			TEXTURE2D(_LutTex);		SAMPLER(sampler_LutTex);
	
			CBUFFER_START(UnityPerMaterial)
				float4 _MainTex_ST;
				half _Lerp;
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

			half3 GetLutColor(Texture2D lutTex, SamplerState sampler_lutTex, half3 color)
			{
				const half OFFSET_X = 0.5 / 256.0;
				const half OFFSET_Y = 0.5 / 16.0;
				const half SCALE = 15.0 / 16.0;

				half b_integer = floor(color.b * 14.9999) / 16.0;
				half b_fractional = color.b * 15.0 - b_integer * 16.0;

				half u = OFFSET_X + b_integer + color.r * SCALE / 16.0;
				half v = 1 - (OFFSET_Y + color.g * SCALE);

				return lerp(
					SAMPLE_TEXTURE2D(lutTex, sampler_lutTex, half2(u             , v)).rgb,
					SAMPLE_TEXTURE2D(lutTex, sampler_lutTex, half2(u + 1.0 / 16.0, v)).rgb,
					b_fractional
				);
			}

			half4 frag(VStoFS IN) : SV_Target
			{
				half3 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;
				half3 lutedTex = GetLutColor(_LutTex, sampler_LutTex, mainTex);
				return half4(lerp(mainTex, lutedTex, _Lerp), 1);
			}
			ENDHLSL
		}
	}
}
