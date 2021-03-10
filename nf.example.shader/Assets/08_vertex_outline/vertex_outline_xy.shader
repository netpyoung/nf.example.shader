Shader "NFShader/Outline/vertex_outline_xy"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_OutlineThickness("_OutlineThickness", Float) = 0.02
		_OutlineColor("_OutlineColor", Color) = (1,1,1,1)
	}

	SubShader
	{
		Tags
		{
			"RenderPipeline" = "UniversalRenderPipeline"
		}

		Pass
		{
			Name "Outline"

			Tags
			{
				"LightMode" = "SRPDefaultUnlit"
				"Queue" = "Geometry"
				"RenderType" = "Opaque"
			}

			Cull Front

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			CBUFFER_START(UnityPerMaterial)
				float _OutlineThickness;
				float4 _OutlineColor;
			CBUFFER_END

			struct Attributes
			{
				float4 positionOS	: POSITION;
				float2 uv			: TEXCOORD0;
				float3 normal		: NORMAL;
			};

			struct Varyings
			{
				float4 positionHCS	: SV_POSITION;
				float2 uv			: TEXCOORD0;
			};

			inline float2 TransformViewToProjection(float2 v)
			{
				return mul((float2x2)UNITY_MATRIX_P, v);
			}

			Varyings vert(Attributes IN)
			{
				Varyings OUT;
				ZERO_INITIALIZE(Varyings, OUT);


				/*float3 worldNormalLength = length(TransformObjectToWorldNormal(v.normal));
				float3 outlineOffset = _OutlineThickness * worldNormalLength * v.normal;
				v.vertex.xyz += outlineOffset;
				o.vertex = TransformObjectToHClip(v.vertex.xyz);*/

				OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);

				half3 normalVS = mul((float3x3)UNITY_MATRIX_IT_MV, IN.normal);
				half2 offsetPS = TransformViewToProjection(normalVS.xy);
				OUT.positionHCS.xy += offsetPS * _OutlineThickness;

				return OUT;
			}

			half4 frag(Varyings IN) : SV_Target
			{
				return _OutlineColor;
			}
			ENDHLSL
		}

		Pass
		{
			Name "Front"

			Tags
			{
				"LightMode" = "UniversalForward"
				"Queue" = "Geometry"
				"RenderType" = "Opaque"
			}

			Cull Back

			HLSLPROGRAM
			#pragma target 3.5

			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			TEXTURE2D(_MainTex);		SAMPLER(sampler_MainTex);

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
				float4 positionHCS	: SV_POSITION;
				float2 uv			: TEXCOORD0;
			};

			Varyings vert(Attributes IN)
			{
				Varyings OUT;
				ZERO_INITIALIZE(Varyings, OUT);

				OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
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
