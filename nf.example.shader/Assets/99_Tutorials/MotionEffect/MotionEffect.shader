Shader "example/02_texture"
{
	// ref: https://blog.csdn.net/linjf520/article/details/104602728
	Properties
	{
		_MainTex("texture", 2D) = "white" {}
		_MoveDir("Move Direction (x, y, z)", Vector) = (0,0,0,0)
		_MotionTintColor("Motion Tint Color", Color) = (1,1,1,1)
		_InvMaxMotion("_InvMaxMotion", Float) = 3
		_Alpha("_Alpha", Range(0.0, 1.0)) = 0.5
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
			Name ""

			Tags
			{
				"LightMode" = "SRPDefaultUnlit"
			}

			ZWrite off Cull off
			Blend SrcAlpha OneMinusSrcAlpha

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			TEXTURE2D(_MainTex);	SAMPLER(sampler_MainTex);

			CBUFFER_START(UnityPerMaterial)
				float4 _MainTex_ST;

				float4 _MoveDir;
				float4 _MotionTintColor;
				float _InvMaxMotion;
				float _Alpha;
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
				float3 N			: TEXCOORD1;
			};

			float2 hash22(float2 p)
			{
				p = float2(dot(p, float2(127.1, 311.7)), dot(p, float2(269.5, 183.3)));
				return -1.0 + 2.0 * frac(sin(p) * 43758.5453123);
			}

			float perlin_noise(float2 p)
			{
				float2 pi = floor(p);
				float2 pf = p - pi;
				float2 w = pf * pf * (3.0 - 2.0 * pf);

				float a = lerp(
					dot(hash22(pi + float2(0.0, 0.0)), pf - float2(0.0, 0.0)),
					dot(hash22(pi + float2(1.0, 0.0)), pf - float2(1.0, 0.0)),
					w.x
				);
				float b = lerp(
					dot(hash22(pi + float2(0.0, 1.0)), pf - float2(0.0, 1.0)),
					dot(hash22(pi + float2(1.0, 1.0)), pf - float2(1.0, 1.0)),
					w.x
				);
				return lerp(a, b, w.y);
			}
			VStoFS vert(APPtoVS IN)
			{
				VStoFS OUT;
				ZERO_INITIALIZE(VStoFS, OUT);


				half3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
				half3 N = TransformObjectToWorldNormal(IN.normal);

				half MdotN = max(0, dot(_MoveDir.xyz, N));
				half offsetFactor = (perlin_noise(IN.positionOS.xy) * 0.5 + 0.5) * MdotN;

				positionWS += _MoveDir.xyz * offsetFactor * _MoveDir.w;
				
				OUT.positionCS = TransformWorldToHClip(positionWS);
				OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
				OUT.N = N;

				return OUT;
			}

			half4 frag(VStoFS IN) : SV_Target
			{
				half3 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;

				half alpha = _Alpha * saturate(1 - (IN.N.z * _InvMaxMotion));
				return half4(mainTex * _MotionTintColor.rgb, alpha);
			}
			ENDHLSL
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

			CBUFFER_START(UnityPerMaterial)
				float4 _MainTex_ST;

				float4 _MoveDir;
				float4 _MotionTintColor;
				float _InvMaxMotion;
				float _Alpha;
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
