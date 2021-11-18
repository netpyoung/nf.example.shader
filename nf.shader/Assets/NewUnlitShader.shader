Shader "NF/Toon/Matcap"
{
	Properties
	{
		[Header(Diffuse)]
		_DiffuseColor("_DiffuseColor", Color) = (1, 1, 1, 1)
		[NoScaleOffset] _MainTex("Texture", 2D) = "white" {}
		[NoScaleOffset] _MatcapDiffuseTex("_MatcapDiffuseTex", 2D) = "black" {}

		[Header(Specular)]
		_SpecularColor("_SpecularColor", Color) = (1, 1, 1, 1)
		_SpecularAmount("_SpecularAmount", Float) = 0.5
		[NoScaleOffset] _SpecularMaskTex("_SpecularMaskTex", 2D) = "white" {}
		[NoScaleOffset] _MatcapSpecularTex("_MatcapSpecularTex", 2D) = "black" {}

		_MultipleColor("_MultipleColor", Color) = (1, 1, 1, 1)
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
			Name "VERTEX_OUTLINE_XY_BACK"

			Tags
			{
				"LightMode" = "SRPDefaultUnlit"
			}

			ColorMask RGB
			Cull Front

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			CBUFFER_START(UnityPerMaterial)
			CBUFFER_END

			struct APPtoVS
			{
				float4 positionOS	: POSITION;
				float2 uv			: TEXCOORD0;
				float3 normal		: NORMAL;
			};

			struct VStoFS
			{
				float4 positionCS	: SV_POSITION;
				float2 uv			: TEXCOORD0;
			};

			inline float2 TransformViewToProjection(float2 v)
			{
				return mul((float2x2)UNITY_MATRIX_P, v);
			}

			VStoFS vert(APPtoVS IN)
			{
				VStoFS OUT;
				ZERO_INITIALIZE(VStoFS, OUT);

				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				half4 normalCS = TransformObjectToHClip(IN.normal);
				half2 offset = normalize(normalCS.xy) / _ScreenParams.xy * (2 * 1.5) * OUT.positionCS.w;

				OUT.positionCS.xy += offset;

				return OUT;
			}

			half4 frag(VStoFS IN) : SV_Target
			{
				return 0;
			}
			ENDHLSL
		}

		Pass
		{
			Tags
			{
				"LightMode" = "UniversalForward"
			}

			Cull Back

			HLSLPROGRAM
			#pragma target 3.5
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			#pragma vertex vert
			#pragma fragment frag

			TEXTURE2D(_MainTex);			SAMPLER(sampler_MainTex);
			TEXTURE2D(_MatcapDiffuseTex);	SAMPLER(sampler_MatcapDiffuseTex);
			TEXTURE2D(_SpecularMaskTex);	SAMPLER(sampler_SpecularMaskTex);
			TEXTURE2D(_MatcapSpecularTex);	SAMPLER(sampler_MatcapSpecularTex);
			
			CBUFFER_START(UnityPerMaterial)
			CBUFFER_END

			half _SpecularAmount;
			half3 _DiffuseColor;
			half3 _SpecularColor;
			half3 _MultipleColor;

			struct APPtoVS
			{
				float4 positionOS	: POSITION;
				float3 normalOS     : NORMAL;
				float2 uv			: TEXCOORD0;
			};

			struct VStoFS
			{
				float4 positionCS	: SV_POSITION;
				float2 uv           : TEXCOORD0;

				float3 N            : TEXCOORD1;
				float3 V            : TEXCOORD2;
				float3 L            : TEXCOORD3;

				float2 uv_Matcap	: TEXCOORD4;
			};

			VStoFS vert(APPtoVS IN)
			{
				VStoFS OUT;
				ZERO_INITIALIZE(VStoFS, OUT);

				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv = IN.uv;

				half4x4 MATRIX_IT_MV = UNITY_MATRIX_IT_MV;

				half2 normalVS;
				normalVS.x = dot(MATRIX_IT_MV[0].xyz, IN.normalOS);
				normalVS.y = dot(MATRIX_IT_MV[1].xyz, IN.normalOS);
				OUT.uv_Matcap = normalVS * 0.5 + 0.5;

				return OUT;
			}

			half4 frag(VStoFS IN) : SV_Target
			{
				half3 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;
				half3 matcapDiffuseTex = SAMPLE_TEXTURE2D(_MatcapDiffuseTex, sampler_MatcapDiffuseTex, IN.uv_Matcap).rgb;
				half3 diffuse = saturate(matcapDiffuseTex) * 0.5 + 0.5;

				half3 specularMaskTex = SAMPLE_TEXTURE2D(_SpecularMaskTex, sampler_SpecularMaskTex, IN.uv).rgb;
				half3 matcapSpecularTex = SAMPLE_TEXTURE2D(_MatcapSpecularTex, sampler_MatcapSpecularTex, IN.uv_Matcap).rgb;
				matcapSpecularTex *= _SpecularColor;
				matcapSpecularTex *= _SpecularAmount;

				half3 specular_add_R = matcapSpecularTex * specularMaskTex.r;

				half4 finalColor = float4(mainTex * diffuse * _DiffuseColor + specular_add_R, 1);
				finalColor.rgb *= _MainLightColor.rgb;
				finalColor.rgb *= _MultipleColor;

				return finalColor;
			}
			ENDHLSL
		}
	}
}