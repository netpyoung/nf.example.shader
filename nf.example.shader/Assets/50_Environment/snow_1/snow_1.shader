Shader "snow_1"
{
	Properties
	{
		_MainTex("Main Texture", 2D) = "white" {}

		_SnowPerc("Snow %", Range(0, 1)) = 0.3
		_SnowHeight("Snow Height", Float) = 0.0002
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
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			TEXTURE2D(_MainTex);		SAMPLER(sampler_MainTex);

			CBUFFER_START(UnityPerMeterial)
				half4 _MainTex_ST;

				half _SnowPerc;
				half _SnowHeight;
			CBUFFER_END

			struct APPtoVS
			{
				float4 positionOS	: POSITION;
				float3 normalOS     : NORMAL;
				float2 uv			: TEXCOORD0;
			};

			struct VStoFS
			{
				float4 positionCS	: SV_POSITION;
				float2 uv			: TEXCOORD0;

				float3 N            : TEXCOORD1;
			};

			VStoFS vert(APPtoVS IN)
			{
				VStoFS OUT;
				ZERO_INITIALIZE(VStoFS, OUT);
				
				half3 N = TransformObjectToWorldNormal(IN.normalOS);
				if (dot(N, (half3(0, 1, 0))) >= (1- _SnowPerc) * 2 - 1)
				{
					IN.positionOS.xyz += IN.positionOS.xyz * _SnowHeight;
				}

				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
				OUT.N = N;

				return OUT;
			}

			half4 frag(VStoFS IN) : SV_Target
			{
				half3 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;

				Light light = GetMainLight();

				half3 N = normalize(IN.N);
				half3 L = normalize(light.direction);

				half NdotL = saturate(dot(N, L));

				half3 diffuse = NdotL * mainTex;
				if (dot(N, half3(0, 1, 0)) >= (1 - _SnowPerc) * 2 - 1)
				{
					diffuse = 1;
				}

				return half4(diffuse, 1);
			}
			ENDHLSL
		}
	}
}
