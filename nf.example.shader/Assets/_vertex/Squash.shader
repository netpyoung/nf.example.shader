Shader "Squash"
{
	// ref: bzyzhang.github.io/2020/11/28/2020-11-28-（一）顶点动画/
	Properties
	{
		_MainTex("texture", 2D) = "white" {}
		_TopY("Top Y", Float) = 1
		_BottomY("Bottom Y", Float) = 0
		_Control("Control", Range(0, 1)) = 0
	}

	SubShader
	{
		Pass
		{
			Tags
			{
				"RenderPipeline" = "UniversalRenderPipeline"
				"LightMode" = "UniversalForward"
				"RenderType" = "Opaque"
				"Queue" = "Geometry"
				"IgnoreProjector" = "True"
			}

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

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

			Varyings vert(Attributes IN)
			{
				Varyings OUT;
				ZERO_INITIALIZE(Varyings, OUT);

				half3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
				half normalizeDist = GetNormalizeDist(positionWS.y);

				half3 localNegativeY = TransformWorldToObjectDir(half3(0, -1, 0));
				half value = saturate(_Control - normalizeDist);
				IN.positionOS.xyz += localNegativeY * value;

				OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

				return OUT;
			}

			half4 frag(Varyings IN) : SV_Target
			{
				half3 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;
				return half4(color, 1);
			}
			ENDHLSL
		}
	}
}
