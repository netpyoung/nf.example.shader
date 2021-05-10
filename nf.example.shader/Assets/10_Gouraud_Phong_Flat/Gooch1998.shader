Shader "example/Gooch98"
{
	Properties
	{
		_MainTex("Texture", 2D)			= "white" {}
		_Ambient("Ambient", Color)		= (1, 1, 1, 1)
		_Diffuse("Diffuse", Color)		= (1, 1, 1, 1)
		_Specular("Specular", Color)	= (1, 1, 1, 1)
		_Ks("Ks", Float)				= 1
		_Kd_A("Kd_A", Float)			= 0.2
		_Kd_B("Kd_B", Float)			= 0.6
		_Ka("Ka", Float)				= 1
		_Yellow("_Yellow", Range(0, 1)) = 0.4
		_Blue("_Blue", Range(0, 1))		= 0.4
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
				float _Kd_A;
				float _Kd_B;
				float _Ka;
				float _Yellow;
				float _Blue;
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

			VStoFS vert(APPtoVS IN)
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

				float NdotL = dot(N, L);
				float halfLambert = NdotL * 0.5 + 0.5;

				float3 Kblue = float3(0, 0, _Blue);
				float3 Kyellow = float3(_Yellow, _Yellow, 0);
				float3 Kcool = Kblue + _Kd_A;
				float3 Kwarm = Kyellow + _Kd_B;

				float darkness = 0.5;
				float3 gooch98 = lerp(Kcool, Kwarm, halfLambert);
				float select = (saturate(NdotL - 0.6) * 0.5 + 0.1);
				float3 finalTone = (_Diffuse * select) + (gooch98 * darkness);

				float3 diffuseColor = _Ambient * _Ka + finalTone;
				float3 specularColor = _Specular * _Ks * pow(max(0, dot(R, V)), 20);

				float4 finalColor = float4((diffuseColor) * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb + specularColor, 1);
				return finalColor;
			}
			ENDHLSL
		}
	}
}
