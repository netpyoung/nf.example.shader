Shader "Matcap_witout_bump"
{
	Properties
	{
		_MainTex("texture", 2D) = "white" {}
		_MatcapTex("_MatcapTex", 2D) = "white" {}
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
			TEXTURE2D(_MatcapTex);	SAMPLER(sampler_MatcapTex);
	
			CBUFFER_START(UnityPerMaterial)
				float4 _MainTex_ST;
			CBUFFER_END

			struct APPtoVS
			{
				float4 positionOS	: POSITION;
				float2 uv			: TEXCOORD0;
				float3 normalOS		: NORMAL;
			};

			struct VStoFS
			{
				float4 positionCS	: SV_POSITION;
				float2 uv			: TEXCOORD0;
				float2 uv_Matcap	: TEXCOORD1;
			};

			VStoFS vert(APPtoVS IN)
			{
				VStoFS OUT;
				ZERO_INITIALIZE(VStoFS, OUT);

				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
				
				// #define UNITY_MATRIX_IT_MV transpose(mul(UNITY_MATRIX_I_M, UNITY_MATRIX_I_V))
				half4x4 IT_MV = UNITY_MATRIX_IT_MV;

				half2 normalVS;
				normalVS.x = dot(IT_MV[0].xyz, IN.normalOS);
				normalVS.y = dot(IT_MV[1].xyz, IN.normalOS);
				OUT.uv_Matcap = normalVS * 0.5 + 0.5;

				return OUT;
			}

			half4 frag(VStoFS IN) : SV_Target
			{
				half3 matcapTex = SAMPLE_TEXTURE2D(_MatcapTex, sampler_MatcapTex, IN.uv_Matcap).rgb;

				return half4(matcapTex * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb, 1);
			}
			ENDHLSL
		}
	}
}
