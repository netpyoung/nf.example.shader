Shader "grass_boom"
{
	Properties
	{
		_FxRenderTex("_FxRenderTex", 2D) = "white" {}
	}

	SubShader
	{
		Tags
		{
			"RenderPipeline" = "UniversalRenderPipeline"
			"Queue" = "Transparent"
			"RenderType" = "Transparent"
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

			TEXTURE2D(_MainTex);		SAMPLER(sampler_MainTex);
			TEXTURE2D(_FxRenderTex);	SAMPLER(sampler_FxRenderTex);

			CBUFFER_START(UnityPerMeterial)
				half4 _MainTex_ST;
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

			half2 RotateDegrees(half2 uv, in half2 center, in half degrees)
			{
				uv -= center;

				half alpha = degrees * PI / 180;
				half s; // sin alpha
				half c; // cos alpha
				sincos(alpha, s, c);

				half2x2 m = half2x2(c, -s, s, c);
				m *= 0.5;
				m += 0.5;
				m = m * 2 - 1;

				uv = mul(uv, m);
				uv += center;
				
				return uv;
			}

			void RotateAboutAxis_float(in float4 NormalizedRotationAxisAndAngle, in float3 PositionOnAxis, in float3 Position, out float3 RotatedPosition)
			{
				float3 ClosestPointOnAxis = PositionOnAxis + NormalizedRotationAxisAndAngle.xyz * dot(NormalizedRotationAxisAndAngle.xyz, Position - PositionOnAxis);
				// Construct orthogonal axes in the plane of the rotation
				float3 UAxis = Position - ClosestPointOnAxis;
				float3 VAxis = cross(NormalizedRotationAxisAndAngle.xyz, UAxis);
				float CosAngle;
				float SinAngle;
				sincos(NormalizedRotationAxisAndAngle.w, SinAngle, CosAngle);
				// Rotate using the orthogonal axes
				float3 R = UAxis * CosAngle + VAxis * SinAngle;
				// Reconstruct the rotated world space position
				RotatedPosition = (ClosestPointOnAxis + R);// -Position;
				// Convert from position to a position offset
			}

			VStoFS vert(APPtoVS IN)
			{
				VStoFS OUT;
				ZERO_INITIALIZE(VStoFS, OUT);

				// positionWS to UV.
				float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
				float2 uv = positionWS.xz * 0.1 + 0.5;
				//uv = 1 - RotateDegrees(uv, 0.5, 180);

				float2 fxRenderTex = SAMPLE_TEXTURE2D_LOD(_FxRenderTex, sampler_FxRenderTex, uv, 0).rg;
				fxRenderTex = fxRenderTex * 2 - 1;

				float3 p = cross(normalize(float3(fxRenderTex.r, 0, fxRenderTex.g)), float3(0, -1, 0));
				float angle = length(fxRenderTex) * radians(90);

				// #define SHADERGRAPH_OBJECT_POSITION UNITY_MATRIX_M._m03_m13_m23
				float3 objectPosition = UNITY_MATRIX_M._m03_m13_m23;
				float3 RotatedPositionWS;
				RotateAboutAxis_float(float4(p, angle), objectPosition, positionWS, RotatedPositionWS);

				OUT.positionCS = TransformWorldToHClip(RotatedPositionWS);
				OUT.uv = IN.uv;

				return OUT;
			}

			half4 frag(VStoFS IN) : SV_Target
			{
				return 1;
			}
			ENDHLSL
		}
	}
}
