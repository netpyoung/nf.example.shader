Shader "example/Phong"
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

			struct APPtoVS
			{
				float4 positionOS	: POSITION;
				float3 normalOS     : NORMAL;
				float2 uv			: TEXCOORD0;
			};

			struct VStoFS
			{
				float4 positionCS	: SV_POSITION;
				float2 uv           : TEXCOORD0;

				float3 N            : TEXCOORD1;
				float3 V            : TEXCOORD2;
				float3 L            : TEXCOORD3;
			};

			VStoFS  vert(APPtoVS IN)
			{
				VStoFS OUT;
				ZERO_INITIALIZE(VStoFS, OUT);

				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
				
				Light light = GetMainLight();
				OUT.N = TransformObjectToWorldNormal(IN.normalOS);
				OUT.V = normalize(GetWorldSpaceViewDir(TransformObjectToWorld(IN.positionOS.xyz)));
				OUT.L = normalize(light.direction);
				return OUT;
			}

			half4 frag(VStoFS IN) : SV_Target
			{
				float3 N = normalize(IN.N);
				float3 V = normalize(IN.V);
				float3 L = normalize(IN.L);

				float3 R = reflect(-L, N);

				float3 diffuseColor = _Ambient * _Ka + _Diffuse * _Kd * max(0, dot(N, L));
				float3 specularColor = _Specular * _Ks * pow(max(0, dot(R, V)), 20);

				float4 finalColor = float4((diffuseColor) * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb + specularColor, 1);
				return finalColor;
			}
			ENDHLSL
		}
	}
}
