Shader "FakeThicknessWindow"
{
	Properties
	{
		[Normal] [NoScaleOffset] _NormalTex("_NormalTex", 2D) = "bump" {}
		[NoScaleOffset] [Cube] _EnvCubeTex("_EnvCubeTex", Cube) = "" {}
		[NoScaleOffset] _IdMaskTex("_IdMaskTex", 2D) = "" {}
		[NoScaleOffset] _IdMaskHeightTex("_IdMaskHeightTex", 2D) = "" {}

		_ParallaxScale("_ParallaxScale", Range(0, 20)) = 5
		_GlassColor("_GlassColor", Color) = (0.9, 0.9, 1, 1)
		[HDR] _CrackColor("_CrackColor", Color) = (0.7, 0.9, 1, 1)
		_CrackPower("_CrackPower", Range(1, 10)) = 5
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

			Cull Back

			HLSLPROGRAM
			#pragma target 3.5

			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			TEXTURE2D(_IdMaskTex);			SAMPLER(sampler_IdMaskTex);
			TEXTURE2D(_NormalTex);			SAMPLER(sampler_NormalTex);
			TEXTURE2D(_IdMaskHeightTex);	SAMPLER(sampler_IdMaskHeightTex);
			TEXTURECUBE(_EnvCubeTex);		SAMPLER(sampler_EnvCubeTex);

			CBUFFER_START(UnityPerMaterial)
				half _ParallaxScale;
				half3 _CrackColor;
				half _CrackPower;
				half3 _GlassColor;
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
				OUT.uv = IN.uv;

				ExtractTBN(IN.normalOS, IN.tangent, OUT.T, OUT.B, OUT.N);

				OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
				return OUT;
			}

			half2 ParallaxMappingUV(TEXTURE2D_PARAM(heightMap, sampler_heightMap), half2 uv, half3 V_TS, half amplitude)
			{
				// 높이 맵에서 높이를 구하고,
				half height = SAMPLE_TEXTURE2D(heightMap, sampler_heightMap, uv).r;
				height = height * amplitude - amplitude / 2.0;

				// 시선에 대한 offset을 구한다.
				// 시선은 반대방향임으로 부호는 마이너스(-) 붙여준다.
				// TS.xyz == TS.tbn

				// TS.n에 0.42를 더해주어서 0에 수렴하지 않도록(E가 너무 커지지 않도록) 조정.
				half2 E = -(V_TS.xy / (V_TS.z + 0.42));

				// 근사값이기에 적절한 strength를 곱해주자.
				return uv + E * height;
			}

			half4 frag(VStoFS IN) : SV_Target
			{
				Light light = GetMainLight();
				half3 L = normalize(light.direction);
				half3 V = GetWorldSpaceNormalizeViewDir(IN.positionWS);

				half3 T = normalize(IN.T);
				half3 B = normalize(IN.B);
				half3 N = normalize(IN.N);
				
				half3x3 TBN = float3x3(normalize(T), normalize(B), normalize(N));

				half2 parallaxUV = ParallaxMappingUV(_IdMaskHeightTex, sampler_IdMaskHeightTex, IN.uv, mul(TBN, V), _ParallaxScale * 0.01);

				half idMaskTex			= SAMPLE_TEXTURE2D(_IdMaskTex, sampler_IdMaskTex, IN.uv).r;
				half idMaskParallaxTex	= SAMPLE_TEXTURE2D(_IdMaskTex, sampler_IdMaskTex, parallaxUV).r;
				
				half cross = 0;
				if (idMaskTex != idMaskParallaxTex)
				{
					cross = 1;
				}
				//return half4(cross, cross, cross, 1);                       // [== debug color ==]

				half NdotL = dot(N, L);
				
				half3 parallaxNormalTex = UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, parallaxUV));
				half3 crossN = normalize(mul(parallaxNormalTex, TBN)) * cross;
				half crossDiffuse = dot(crossN, L);

				if (NdotL < 0.01)
				{
					// 어두워질때 crossDiffuse만 밝아지는걸 방지하기 위한코드.
					crossDiffuse = NdotL * cross;
				}
				// return half4(crossDiffuse, crossDiffuse, crossDiffuse, 1); // [== debug color ==]

				half specular = pow(max(0.0, dot(reflect(-L, IN.N), V)), 20);
				// return half4(specular, specular, specular, 1);             // [== debug color ==]

				half3 envCubeTex = SAMPLE_TEXTURECUBE(_EnvCubeTex, sampler_EnvCubeTex, reflect(-V, saturate(crossN + IN.N))).rgb;
				// return half4(envCubeTex, 1);                               // [== debug color ==]

				half3 finalCrackColor = (envCubeTex * crossDiffuse * _CrackColor * _CrackPower);
				// return half4(finalCrackColor, 1);                          // [== debug color ==]

				half3 finalGlassColor = (envCubeTex * NdotL * _GlassColor + specular);
				// return half4(finalGlassColor, 1);                          // [== debug color ==]

				half3 finalColor = saturate(finalGlassColor + finalCrackColor);
				return half4(finalColor, 1);
			}
			ENDHLSL
		}
	}
}
