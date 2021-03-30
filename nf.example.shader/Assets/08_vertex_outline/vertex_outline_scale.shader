Shader "NFShader/Outline/vertex_outline_scale"
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
			Blend SrcAlpha OneMinusSrcAlpha

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			CBUFFER_START(UnityPerMaterial)
				float _OutlineThickness;
				float4 _OutlineColor;
				float4 _MainTex_ST;
			CBUFFER_END

			struct Attributes
			{
				float4 positionOS	: POSITION;
				float2 uv			: TEXCOORD0;
			};

			struct Varyings
			{
				float4 positionCS : SV_POSITION;
			};

			float4 Scale(float4 vertexPosition, float3 s)
			{
				float4x4 m;
				m[0][0] = 1.0 + s.x; m[0][1] = 0.0;       m[0][2] = 0.0;       m[0][3] = 0.0;
				m[1][0] = 0.0;       m[1][1] = 1.0 + s.y; m[1][2] = 0.0;       m[1][3] = 0.0;
				m[2][0] = 0.0;       m[2][1] = 0.0;       m[2][2] = 1.0 + s.z; m[2][3] = 0.0;
				m[3][0] = 0.0;       m[3][1] = 0.0;       m[3][2] = 0.0;       m[3][3] = 1.0;
				return mul(m, vertexPosition);
			}

			Varyings  vert(Attributes IN)
			{
				Varyings OUT;
				ZERO_INITIALIZE(Varyings, OUT);

				IN.positionOS = Scale(IN.positionOS, _OutlineThickness);
				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);

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
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite On
			ZTest LEqual

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);

			CBUFFER_START(UnityPerMaterial)
				float _OutlineThickness;
				float4 _OutlineColor;
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
