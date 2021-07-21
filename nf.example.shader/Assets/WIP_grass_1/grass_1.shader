Shader "grass_1"
{
	Properties
	{
		_MainTex("Main Texture", 2D) = "white" {}

		_PaintTex("Paint Texture", 2D) = "white" {}

		_GrassColor("Grass Color", Color) = (0.5, 1, 0.5, 1)

		
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
			TEXTURE2D(_PaintTex);		SAMPLER(sampler_PaintTex);

			CBUFFER_START(UnityPerMeterial)
				half4 _MainTex_ST;
				
				half3 _GrassColor;
				half _WindSpeed;
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
				
				
				half3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
				positionWS.x += _WindSpeed * _Time.y;
				OUT.positionCS = TransformWorldToHClip(positionWS);
				OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
				OUT.N = TransformObjectToWorldDir(IN.normalOS);

				return OUT;
			}

			half4 frag(VStoFS IN) : SV_Target
			{
				half3 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;
				half3 paintTex = SAMPLE_TEXTURE2D(_PaintTex, sampler_PaintTex, IN.uv).rgb;

				Light light = GetMainLight();

				half3 N = normalize(IN.N);
				half3 L = normalize(light.direction);

				half NdotL = saturate(dot(N, L));

				half3 diffuse = NdotL * mainTex * _GrassColor;
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
