Shader "example/Gouraud"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_Ambient("Ambient", Color) = (1, 1, 1, 1)
		_Diffuse("Diffuse", Color) = (1, 1, 1, 1)
		_Specular("Specular", Color) = (1, 1, 1, 1)
		_Ks("Ks", Float) = 1
		_Kd("Kd", Float) = 1
		_Ka("Ka", Float) = 1
	}

	SubShader
	{
		Pass
		{
			Tags
			{
				"RenderType" = "Opaque"
				"RenderPipeline" = "UniversalRenderPipeline"
			}

			HLSLPROGRAM
			#pragma target 3.5

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			#pragma vertex vert
			#pragma fragment frag

			TEXTURE2D(_MainTex);
			SAMPLER(sampler_MainTex);

			CBUFFER_START(UnityPerMaterial)
				float4 _MainTex_ST;
				float3 _Ambient;
				float3 _Diffuse;
				float3 _Specular;
				float _Ks;
				float _Kd;
				float _Ka;
			CBUFFER_END

			struct Attributes
			{
				float4 positionOS	: POSITION;
				float3 normalOS     : NORMAL;
				float2 uv			: TEXCOORD0;
			};

			struct Varyings
			{
				float4 positionHCS	: SV_POSITION;
				float2 uv           : TEXCOORD0;
				float3 Diff			: TEXCOORD1;
				float3 Spec			: TEXCOORD2;
			};

			Varyings  vert(Attributes IN)
			{
				Varyings OUT;
				ZERO_INITIALIZE(Varyings, OUT);

				OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
				
				Light light = GetMainLight();
				float3 N = TransformObjectToWorldNormal(IN.normalOS);
				float3 V = normalize(GetWorldSpaceViewDir(TransformObjectToWorld(IN.positionOS.xyz)));
				float3 L = normalize(light.direction);
				float3 H = normalize(L + V);
				float3 R = reflect(-L, N);

				OUT.Diff = _Ambient* _Ka + _Diffuse * _Kd * max(0, dot(N, L));
				OUT.Spec = _Specular * _Ks * pow(max(0, dot(R, V)), 20);
				return OUT;
			}

			half4 frag(Varyings  IN) : SV_Target
			{
				return half4(SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb * IN.Diff + IN.Spec, 1);
			}
			ENDHLSL
		}
	}
}
