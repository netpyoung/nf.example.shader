Shader "Squash"
{
	// ref: bzyzhang.github.io/2020/11/28/2020-11-28-（一）顶点动画/
	Properties
	{
		_MainTex("texture", 2D)				= "white" {}
		_TopY("Top Y", Float)				= 1
		_BottomY("Bottom Y", Float)			= 0
		_Control("Control", Range(0, 1))	= 0
	}

	SubShader
	{
		Tags
		{
			"RenderPipeline" = "UniversalRenderPipeline"
			"RenderType" = "Opaque"
			"Queue" = "Geometry"
		}

		Pass
		{
			Name "SQUASH"

			Tags
			{
				"LightMode" = "UniversalForward"
			}

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			struct APPtoVS
			{
				float4 positionOS	: POSITION;
				float2 uv			: TEXCOORD0;
			};

			struct VStoFS
			{
				float4 positionCS	: SV_POSITION;
				float2 uv			: TEXCOORD0;
			};

			TEXTURE2D(_MainTex);		SAMPLER(sampler_MainTex);

			CBUFFER_START(UnityPerMaterial)
				float4 _MainTex_ST;

				half _TopY;
				half _BottomY;
				half _Control;
			CBUFFER_END

			half GetNormalizeDist(half worldY)
			{
				half range = _TopY - _BottomY;
				half distance = _TopY - worldY;
				return saturate(distance / range);
			}

			VStoFS vert(APPtoVS IN)
			{
				VStoFS OUT;
				ZERO_INITIALIZE(VStoFS, OUT);

				half3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
				half normalizeDist = GetNormalizeDist(positionWS.y);

				half3 localNegativeY = TransformWorldToObjectDir(half3(0, -1, 0));
				half value = saturate(_Control - normalizeDist);
				IN.positionOS.xyz += localNegativeY * value;

				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

				return OUT;
			}

			half4 frag(VStoFS IN) : SV_Target
			{
				half3 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;
				return half4(color, 1);
			}
			ENDHLSL
		}
	}
}
