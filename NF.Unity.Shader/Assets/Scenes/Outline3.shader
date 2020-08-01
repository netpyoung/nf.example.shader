Shader "NFShader/Outline/Outline3"
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
				HLSLPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

				struct appdata
				{
					float4 vertex : POSITION;
					float2 uv : TEXCOORD0;
					float3 normal : NORMAL;

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
				inline float2 TransformViewToProjection(float2 v) {
					return mul((float2x2)UNITY_MATRIX_P, v);
				}
				v2f vert(appdata v)
				{
					v2f o;
					UNITY_SETUP_INSTANCE_ID(v);
					UNITY_TRANSFER_INSTANCE_ID(v, o);

					/*float3 worldNormalLength = length(TransformObjectToWorldNormal(v.normal));
					float3 outlineOffset = _OutlineThickness * worldNormalLength * v.normal;
					v.vertex.xyz += outlineOffset;
					o.vertex = TransformObjectToHClip(v.vertex.xyz);*/

					o.vertex = TransformObjectToHClip(v.vertex.xyz);
					float3 normalVS = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
					float2 offsetPS = TransformViewToProjection(normalVS.xy);
					o.vertex.xy += offsetPS * _OutlineThickness;

					
					return o;
				}

				half4 frag(v2f Input) : SV_Target
				{
					UNITY_SETUP_INSTANCE_ID(Input);

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
				}

				Cull Back
								
				HLSLPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

				CBUFFER_START(UnityPerMaterial)
				TEXTURE2D(_MainTex);
				SAMPLER(sampler_MainTex);
				float4 _MainTex_ST;
				CBUFFER_END

				struct appdata
				{
					float4 vertex : POSITION;
					float2 texcoord : TEXCOORD0;
					UNITY_VERTEX_INPUT_INSTANCE_ID
				};

				struct v2f
				{
					float4 vertex : SV_POSITION;
					float2 texcoord : TEXCOORD0;
					UNITY_VERTEX_INPUT_INSTANCE_ID
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

				half4 frag(v2f Input) : SV_Target
				{
					UNITY_SETUP_INSTANCE_ID(Input);

					return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, Input.texcoord);
				}
				ENDHLSL
			}
		}
}
