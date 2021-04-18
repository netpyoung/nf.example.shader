Shader "cracked_ice"
{
	Properties
	{
		_MainTex("_MainTex", 2D) = "white" {}
		[NoScaleOffset]_MaskTex("_MaskTex", 2D) = "white" {}
		[NoScaleOffset][Normal]_NormalTex("_NormalTex", 2D) = "bump" {}

		_MaskIterCount("_MaskIterCount", Float) = 15
		_Offset("_Offset", Range(0, 10)) = 3
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
			Name "CRACKED_ICE"

			Tags
			{
				"LightMode" = "UniversalForward"
			}

			HLSLPROGRAM
			#pragma target 3.5

			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			TEXTURE2D(_MainTex);		SAMPLER(sampler_MainTex);
			TEXTURE2D(_MaskTex);		SAMPLER(sampler_MaskTex);
			TEXTURE2D(_NormalTex);		SAMPLER(sampler_NormalTex);

			CBUFFER_START(UnityPerMaterial)
				float4 _MainTex_ST;
				int _MaskIterCount;
				half _Offset;
			CBUFFER_END

			struct APPtoVS
			{
				float4 positionOS	: POSITION;
				float3 normalOS     : NORMAL;
				float4 tangent      : TANGENT;

				float2 uv			: TEXCOORD0;
			};

			struct VStoFS
			{
				float4 positionCS	: SV_POSITION;
				float2 uv			: TEXCOORD0;

				float3 T			: TEXCOORD1;
				float3 B			: TEXCOORD2;
				float3 N			: TEXCOORD3;

				float3 positionWS	: TEXCOORD4;
			};

			inline void ExtractTBN(in half3 normalOS, in float4 tangent, inout half3 T, inout half3  B, inout half3 N)
			{
				N = TransformObjectToWorldNormal(normalOS);
				T = TransformObjectToWorldDir(tangent.xyz);
				B = cross(N, T) * tangent.w * unity_WorldTransformParams.w;
			}

			VStoFS vert(APPtoVS IN)
			{
				VStoFS OUT;
				ZERO_INITIALIZE(VStoFS, OUT);

				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

				ExtractTBN(IN.normalOS, IN.tangent, OUT.T, OUT.B, OUT.N);

				OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
				return OUT;
			}

			half ParallaxMappingMask(TEXTURE2D_PARAM(maskTex, sampler_maskTex), in half2 uv, in half3 V_TS, in half parallaxOffset, in int iterCount)
			{
				half one = 1;
				half parallaxedMask = 0;
				half result = 1;
				half2 parallaxUV;
				half totalOffset = 0.0;
				half pOffset = parallaxOffset * -0.001;

				for (half i = 0; i < iterCount; ++i)
				{
					totalOffset += pOffset;
					parallaxUV = uv + half2(V_TS.x * totalOffset, V_TS.y * totalOffset);
					parallaxedMask = SAMPLE_TEXTURE2D(maskTex, sampler_maskTex, parallaxUV).r;
					result *= clamp(parallaxedMask + (i / iterCount), 0, 1);
				}

				return result;
			}

			half3 Unity_Blend_Overlay(half3 Base, half3 Blend, half Opacity)
			{
				half3 result1 = 1.0 - 2.0 * (1.0 - Base) * (1.0 - Blend);
				half3 result2 = 2.0 * Base * Blend;
				half3 zeroOrOne = step(Base, 0.5);
				half3 Out = result2 * zeroOrOne + (1 - zeroOrOne) * result1;
				return lerp(Base, Out, Opacity);
			}

			half4 frag(VStoFS IN) : SV_Target
			{
				Light light = GetMainLight();
				half3 L = normalize(light.direction);
				half3 V = GetWorldSpaceNormalizeViewDir(IN.positionWS);

				half3 T = normalize(IN.T);
				half3 B = normalize(IN.B);
				half3 N = normalize(IN.N);
				half3x3 TBN = half3x3(T, B, N);

				half3 mainNormalTS = UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, IN.uv));
				N = normalize(mul(mainNormalTS, TBN));

				half3 V_TS = mul(TBN, V);

				half NdotL = dot(N, L);
				half3 R = reflect(-L, N);

				half diffuse = NdotL * 0.5 + 0.5;
				half specular = pow(max(0.0, dot(R, V)), 22);

				half maskTex = ParallaxMappingMask(_MaskTex, sampler_MaskTex, IN.uv, V_TS, _Offset, _MaskIterCount);
				maskTex = 1 - maskTex;

				// return half4(maskTex, maskTex, maskTex, 1);                     // [== debug color ==]

				half3 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;

				half3 blended = Unity_Blend_Overlay(mainTex, maskTex, 0.6);

				half3 finalColor = diffuse * blended + specular;
				return half4(finalColor, 1);
			}
			ENDHLSL
		}
	}
}

