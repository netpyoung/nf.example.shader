Shader "Distortion_tv"
{
	Properties
	{
		_MainTex("Sprite Texture", 2D) = "white" { }
		_Color("Tint", Color) = (1,1,1,1)
		_BackgroundColor("Barckground Color (RGBA)", Color) = (0,0,0,1)
		_AdjustColor("Adjust Color (RGB)", Color) = (0,0,0,1)
		_DistortionTex("Distortion Tex (RG)", 2D) = "gray" { }
		_DistortionFrequency("Distortion Frequency", Float) = 1
		_DistortionAmplitude("Distortion Amplitude", Range(0, 1)) = 1
		_DistortionAnmSpeed("Distortion Animation Speed", Float) = 1
		_ColorScatterStrength("Color Scatter Strength", Range(-0.1, 0.1)) = 0.01
		_NoiseTex("Noise Tex (RGB)", 2D) = "black" { }
		_NoiseAnmSpeed("Noise Animation Speed", Float) = 1
		_NoiseStrength("Noise Strength", Float) = 1
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
			TEXTURE2D(_DistortionTex);	SAMPLER(sampler_DistortionTex);
			TEXTURE2D(_NoiseTex);	SAMPLER(sampler_NoiseTex);

			CBUFFER_START(UnityPerMaterial)
				float4 _MainTex_ST;
				float4 _Color;
				float4 _BackgroundColor;
				float3 _AdjustColor;
				float _DistortionFrequency;
				float _DistortionAmplitude;
				float _DistortionAnmSpeed;
				float _ColorScatterStrength;
				float _NoiseAnmSpeed;
				float _NoiseStrength;
			CBUFFER_END

			struct APPtoVS
			{
				float4 positionOS	: POSITION;
				float2 uv			: TEXCOORD0;
				float4 color		: COLOR;
			};

			struct VStoFS
			{
				float4 positionCS		: SV_POSITION;
				float4 color			: COLOR;
				float2 uv				: TEXCOORD0;
				float2 uvDistortion		: TEXCOORD1;
				float2 uvNoise			: TEXCOORD2;
			};

			half random1f(in half x)
			{
				return frac(sin(dot(x, 12.9898)) * 43758.5453);
			}

			VStoFS vert(APPtoVS IN)
			{
				VStoFS OUT;
				ZERO_INITIALIZE(VStoFS, OUT);

				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

				OUT.uvDistortion.x = _Time.y * _DistortionAnmSpeed;
				OUT.uvDistortion.y = IN.uv.y * _DistortionFrequency;

				OUT.uvNoise.x = IN.uv.x + random1f(_SinTime.w) + random1f(_CosTime.x) * _NoiseAnmSpeed;
				OUT.uvNoise.y = IN.uv.y + random1f(_SinTime.x) + random1f(_CosTime.w) * _NoiseAnmSpeed;
				OUT.color = IN.color * _Color;
				return OUT;
			}

			half4 frag(VStoFS IN) : SV_Target
			{
				half offset = (SAMPLE_TEXTURE2D(_DistortionTex, sampler_DistortionTex, IN.uvDistortion).r - 0.5) * _DistortionAmplitude;
				half2 colorStrength = half2(_ColorScatterStrength, 0.0);

				half2 mainTex_ra = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, (IN.uv + offset) + colorStrength).ra;
				half2 mainTex_ga = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + offset).ga;
				half2 mainTex_ba = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, (IN.uv + offset) - colorStrength).ba;

				half4 color = 0;
				color.ra = mainTex_ra;
				color.ga += mainTex_ga;
				color.ba += mainTex_ba;

				color.rgb *= IN.color.rgb;
				color.a = saturate(color.a);
				if (color.a < 0.5)
				{
					color = _BackgroundColor;
				}

				color.xyz = (1.0 - ((1.0 - color.xyz) * (1.0 - _AdjustColor)));

				half3 noiseTex = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, IN.uvNoise).rgb;
				color.xyz = (1.0 - ((1.0 - color.xyz) * (1.0 - (noiseTex * _NoiseStrength).xyz)));
				return color;
			}
			ENDHLSL
		}
	}
}
