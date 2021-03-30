Shader "NormalMapYminus"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}

		// Texture Type> Default
		// sRGB (Color Texture)> uncheck
		[NoScaleOffset] _NormalTex("Normal Map", 2D) = "bump" {}
		

		[Toggle(ENABLE_NORMALMAP)]
		_EnableNormalMap("NormalMap?", Float) = 0
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

			#pragma shader_feature_local ENABLE_NORMALMAP

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			TEXTURE2D(_MainTex);		SAMPLER(sampler_MainTex);
			TEXTURE2D(_NormalTex);		SAMPLER(sampler_NormalTex);

			CBUFFER_START(UnityPerMaterial)
				float4 _MainTex_ST;
				float _Parallax;
			CBUFFER_END

			struct Attributes
			{
				float4 positionOS   : POSITION;
				float3 normalOS     : NORMAL;
				float4 tangent      : TANGENT;
				float2 uv           : TEXCOORD0;
			};

			struct Varyings
			{
				float4 positionCS      : SV_POSITION;
				float2 uv               : TEXCOORD0;

				float3 T                : TEXCOORD1;
				float3 B                : TEXCOORD2;
				float3 N                : TEXCOORD3;

				float3 positionWS       : TEXCOORD4;
			};

			inline void ExtractTBN(in half3 normalOS, in float4 tangent, inout half3 T, inout half3  B, inout half3 N)
			{
				N = TransformObjectToWorldNormal(normalOS);
				T = TransformObjectToWorldDir(tangent.xyz);
				B = cross(N, T) * tangent.w * unity_WorldTransformParams.w;
			}

			inline half3 CombineTBN(in half3 tangentNormal, in half3 T, in half3  B, in half3 N)
			{
				return mul(tangentNormal, float3x3(normalize(T), normalize(B), normalize(N)));
			}

			Varyings  vert(Attributes IN)
			{
				Varyings OUT;
				ZERO_INITIALIZE(Varyings, OUT);

				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

				ExtractTBN(IN.normalOS, IN.tangent, OUT.T, OUT.B, OUT.N);

				OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);

				return OUT;
			}

			half4 frag(Varyings IN) : SV_Target
			{
				half3 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;
				half3 normalTex = UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, IN.uv));

				// Unity는 Y+를 쓴다.
				// DirectX는 Y-를 쓴다.
				normalTex.y *= -1;  // 유니티에서 y-를 쓰려면 g값을 뒤집어준다.

				Light light = GetMainLight();
#if ENABLE_NORMALMAP
				half3 N = CombineTBN(normalTex, IN.T, IN.B, IN.N);
#else
				half3 N = normalize(IN.N);
#endif
				half3 L = normalize(light.direction);
				half3 R = reflect(-L, N);

				half NdotL = saturate(dot(N, L));

				half3 diffuse = NdotL * mainTex;
				half3 reflect = pow(saturate(dot(N, R)), 22);

				return half4(diffuse + reflect, 1);
			}
			ENDHLSL
		}
	}
}
