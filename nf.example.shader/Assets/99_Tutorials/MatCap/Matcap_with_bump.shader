Shader "MatCap"
{
	Properties
	{
		_MainTex("texture", 2D) = "white" {}
		[Normal] _NormalTex("_NormalTex", 2D) = "bump" {}
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
			TEXTURE2D(_NormalTex);	SAMPLER(sampler_NormalTex);
			TEXTURE2D(_MatcapTex);	SAMPLER(sampler_MatcapTex);
	
			CBUFFER_START(UnityPerMaterial)
				float4 _MainTex_ST;
			CBUFFER_END

			struct APPtoVS
			{
				float4 positionOS	: POSITION;
				float2 uv			: TEXCOORD0;
				float3 normalOS		: NORMAL;
				float4 tangentOS	: TANGENT;
			};

			struct VStoFS
			{
				float4 positionCS	: SV_POSITION;
				float2 uv			: TEXCOORD0;
				float3 N			: TEXCOORD1;
				float3 TtoV0		: TEXCOORD2;
				float3 TtoV1		: TEXCOORD3;
				float4 tangentOS	: TEXCOORD4;
			};

			VStoFS vert(APPtoVS IN)
			{
				VStoFS OUT;
				ZERO_INITIALIZE(VStoFS, OUT);

				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

				float3 binormalOS = cross(IN.normalOS, IN.tangentOS.xyz) * IN.tangentOS.w * unity_WorldTransformParams.w;
				float3x3 TBN_os = float3x3(IN.tangentOS.xyz, binormalOS, IN.normalOS);
				
				OUT.TtoV0 = mul(TBN_os, UNITY_MATRIX_IT_MV[0].xyz);
				OUT.TtoV1 = mul(TBN_os, UNITY_MATRIX_IT_MV[1].xyz);

				return OUT;
			}

			half4 frag(VStoFS IN) : SV_Target
			{
				half3 normalTex = UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, IN.uv));

				half2 uv_Matcap;
				uv_Matcap.x = dot(IN.TtoV0, normalTex);
				uv_Matcap.y = dot(IN.TtoV1, normalTex);
				uv_Matcap = uv_Matcap * 0.5 + 0.5;

				half3 matcapTex = SAMPLE_TEXTURE2D(_MatcapTex, sampler_MatcapTex, uv_Matcap).rgb;

				return half4(matcapTex * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb, 1);
			}
			ENDHLSL
		}
	}
}
