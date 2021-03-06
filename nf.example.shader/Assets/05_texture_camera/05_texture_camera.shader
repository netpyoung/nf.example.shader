﻿Shader "example/05_texture_camera"
{
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
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

			struct APPtoVS
			{
				float4 positionOS : POSITION;
			};

			struct VStoFS
			{
				float4 positionCS : SV_POSITION;
				float3 directionWS : TEXCOORD1;
			};

			VStoFS vert(APPtoVS IN)
			{
				VStoFS OUT;

				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);

				float4 clip = float4(IN.positionOS.xy, 0.0, 1.0);
				OUT.directionWS = mul(UNITY_MATRIX_M, clip).xyz - _WorldSpaceCameraPos;

				return OUT;
			}

			half4 frag(VStoFS IN) : SV_Target
			{
				// https://docs.unity3d.com/Packages/com.unity.render-pipelines.universal@7.1/manual/universalrp-asset.html

				float2 screenUV = (IN.positionCS.xy / IN.positionCS.z) * 0.5f + 0.5f;

				half depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV);
				depth = LinearEyeDepth(depth, _ZBufferParams);
				float3 worldspace = IN.directionWS * depth + _WorldSpaceCameraPos;

				float4 color = float4(worldspace, 1.0);
				return color;
			}

			inline float DiffuseLambert(float3 normalWS, float3 lightDirWS)
			{
				return saturate(dot(normalWS, lightDirWS));
			}

			inline float DiffuseHalfLambert(float3 normalWS, float3 lightDirWS)
			{
				return 0.5 + (dot(normalWS, lightDirWS) * 0.5);
			}

			// N: Normal
			// L: Light
			// R : Reflect
			// V : Viewport
			// H : Halfway(normalize(L + V))

			// L  N  R
			//  \ | /
			//   \|/
			// ---+---
			//     \
			//      \
			//       -L

			//       Phong Reflection Model : max(0, dot(R, N)) ^ S
			// Blinn-Phong Reflection Model : max(0, dot(H, N)) ^ S

			float3 HalfVector(float3 viewDirWS, float3 lightDirWS)
			{
				return normalize(viewDirWS + lightDirWS);
			}

			float3 SpecularPhong(float3 normalWS, float3 reflectWS, float specularPower)
			{
				return pow(saturate(dot(normalWS, reflectWS)), specularPower);
			}

			float3 SpecularBlinnPhong(float3 normalWS, float3 halfVector, float specularPower)
			{
				return pow(saturate(dot(normalWS, halfVector)), specularPower);
			}

			float Fresnel(float3 normalWS, float3 viewDirWS, float fresnelPower)
			{
				return pow((1 - dot(normalWS, viewDirWS)), fresnelPower);
			}
			ENDHLSL
		}
	}
}
