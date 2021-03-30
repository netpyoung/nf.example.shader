Shader "NFShader/Outline/vertex_outline_xy"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_OutlineWidth("_OutlineWidth", Float) = 0.02
		_OutlineColor("_OutlineColor", Color) = (1, 1, 1, 1)
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
				float _OutlineWidth;
				float4 _OutlineColor;
				float4 _MainTex_ST;
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


				half3 N = TransformObjectToWorldNormal(IN.normal);
				half4 normalCS = TransformWorldToHClip(N);

				// �ƿ������� 2�����̹Ƿ�. `normalCS.xy`�� ���ؼ��� ��� �� `normalize`.
				// ī�޶� �Ÿ��� ���� �ƿ������� ũ�Ⱑ ����Ǵ°��� �������� `normalCS.w`�� �����ش�.
				// _ScreenParams.xy (x/y�� ī�޶� Ÿ���ؽ��� ����/����)�� ����� [-1, +1] ������ ����.
				// ���� 2�� ����([-1, +1])�� ������ ���߱� ���� OutlineWidth�� `*2`�� ���ش�.

				half2 offset = (normalize(normalCS.xy) * normalCS.w) / _ScreenParams.xy * (2 * _OutlineWidth);

				// ���ؽ� Į�� �����ָ鼭 ������ ����.
				// offset *= IN.color.r;

				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.positionCS.xy += offset;

				return OUT;
			}

			half4 frag(VStoFS IN) : SV_Target
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
				float _OutlineThickness;
				float4 _OutlineColor;
				float4 _MainTex_ST;
			CBUFFER_END

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

			VStoFS vert(APPtoVS IN)
			{
				VStoFS OUT;
				ZERO_INITIALIZE(VStoFS, OUT);

				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
				return OUT;
			}

			half4 frag(VStoFS IN) : SV_Target
			{
				return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
			}
			ENDHLSL
		}
	}
}
