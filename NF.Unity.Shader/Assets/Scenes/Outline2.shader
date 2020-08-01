Shader "NFShader/Outline/Outline2"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_OutlineThickness("_OutlineThickness", float) = 0.02
		_OutlineColor("_OutlineColor", Color) = (1,1,1,1)
	}
		SubShader
		{
			Tags
			{
				"RenderType" = "Opaque"
				"RenderPipeline" = "UniversalRenderPipeline"
			}
			LOD 100

			Pass
			{
				Name "Outline"
				Cull Front
				Blend SrcAlpha OneMinusSrcAlpha
				HLSLPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

				struct appdata
				{
					float4 vertex : POSITION;
					float2 uv : TEXCOORD0;
					UNITY_VERTEX_INPUT_INSTANCE_ID
				};

				struct v2f
				{
					float4 vertex : SV_POSITION;
					UNITY_VERTEX_INPUT_INSTANCE_ID
				};

				CBUFFER_START(UnityPerMaterial)
				uniform float _OutlineThickness;
				uniform float4 _OutlineColor;
				CBUFFER_END

				float4 Scale(float4 vertexPosition, float3 s)
				{
					float4x4 m;
					m[0][0] = 1.0 + s.x; m[0][1] = 0.0;       m[0][2] = 0.0;       m[0][3] = 0.0;
					m[1][0] = 0.0;       m[1][1] = 1.0 + s.y; m[1][2] = 0.0;       m[1][3] = 0.0;
					m[2][0] = 0.0;       m[2][1] = 0.0;       m[2][2] = 1.0 + s.z; m[2][3] = 0.0;
					m[3][0] = 0.0;       m[3][1] = 0.0;       m[3][2] = 0.0;       m[3][3] = 1.0;
					return mul(m, vertexPosition);
				}

				v2f vert(appdata v)
				{
					v2f o;
					UNITY_SETUP_INSTANCE_ID(v);
					UNITY_TRANSFER_INSTANCE_ID(v, o);

					o.vertex = TransformObjectToHClip(Scale(v.vertex, _OutlineThickness).xyz);
					return o;
				}

				float4 frag(v2f Input) : SV_Target
				{
					UNITY_SETUP_INSTANCE_ID(Input);

					return _OutlineColor;
				}
				ENDHLSL
			}

			Pass
			{
				Name "Front"
				Cull Back
				Blend SrcAlpha OneMinusSrcAlpha
				ZWrite On
				ZTest LEqual

				Tags
				{
					"LightMode" = "UniversalForward"
				}

				HLSLPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

				CBUFFER_START(UnityPerMaterial)
				Texture2D _MainTex;
				SamplerState sampler_MainTex;
				float4 _MainTex_ST;
				CBUFFER_END

				struct appdata
				{
					float4 vertex : POSITION;
					float2 texcoord : TEXCOORD0;
				};

				struct v2f
				{
					float4 vertex : SV_POSITION;
					float2 texcoord : TEXCOORD0;
				};

				v2f vert(appdata v)
				{
					v2f o;
					UNITY_SETUP_INSTANCE_ID(v);
					UNITY_TRANSFER_INSTANCE_ID(v, o);

					o.vertex = TransformObjectToHClip(v.vertex.xyz);
					o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
					return o;
				}

				float4 frag(v2f Input) : SV_Target
				{
					UNITY_SETUP_INSTANCE_ID(Input);

					return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, Input.texcoord);
				}
				ENDHLSL
			}
		}
}
