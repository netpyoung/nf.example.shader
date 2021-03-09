Shader "example/Parallax_packed"
{
	// ref:
	// - tool: https://gumroad.com/l/EasyChannelPacking
	// - Channel Packing : http://wiki.polycount.com/wiki/ChannelPacking
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}

		// RG : Normal
		// B  : Depth
		[NoScaleOffset]_NormalDepthPackedTex("Normal & Depth Map", 2D) = "bump" {}
		_HeightStrength("Height Strength", Range(0, 1)) = 0.1
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
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			#pragma vertex vert
			#pragma fragment frag

			TEXTURE2D(_MainTex);				SAMPLER(sampler_MainTex);
			TEXTURE2D(_NormalDepthPackedTex);	SAMPLER(sampler_NormalDepthPackedTex);
			

			CBUFFER_START(UnityPerMaterial)
				half4 _MainTex_ST;
				half _HeightStrength;
			CBUFFER_END

			struct Attributes
			{
				float4 positionOS   : POSITION;
				float3 normal	    : NORMAL;
				float4 tangent      : TANGENT;
				float2 uv           : TEXCOORD0;
			};

			struct Varyings
			{
				float4 positionHCS      : SV_POSITION;
				float2 uv               : TEXCOORD0;

				float3 L_TS                : TEXCOORD1;
				float3 V_TS                : TEXCOORD2;
			};

			Varyings  vert(Attributes IN)
			{
				Varyings OUT;
				ZERO_INITIALIZE(Varyings, OUT);

				VertexPositionInputs vertexInputs = GetVertexPositionInputs(IN.positionOS.xyz);
				OUT.positionHCS = vertexInputs.positionCS;
				OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

				Light mainLight = GetMainLight();
				VertexNormalInputs normalInputs = GetVertexNormalInputs(IN.normal, IN.tangent);
				half3x3 TBN = half3x3(normalInputs.tangentWS, normalInputs.bitangentWS, normalInputs.normalWS);
				OUT.L_TS = mul(TBN, mainLight.direction);
				OUT.V_TS = mul(TBN, GetCameraPositionWS() - vertexInputs.positionWS);

				return OUT;
			}

			half2 ParallaxMapping(half2 uv, half3 V_TS)
			{
				half height = SAMPLE_TEXTURE2D(_NormalDepthPackedTex, sampler_NormalDepthPackedTex, uv).b;
				half2 E = -(V_TS.xy / V_TS.z); // 시서은 반대방향임으로 마이너스(-).
				return uv + E * (height * _HeightStrength);
			}

			half4 frag(Varyings IN) : SV_Target
			{

				half3 L_TS = normalize(IN.L_TS);
				half3 V_TS = normalize(IN.V_TS);

				half2 uv = ParallaxMapping(IN.uv, V_TS);
				if ((uv.x < 0.0 || 1.0 < uv.x) || (uv.y < 0.0 || 1.0 < uv.y))
				{
					discard;
				}
					
				half4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);

				half3 N_TS = UnpackNormal(SAMPLE_TEXTURE2D(_NormalDepthPackedTex, sampler_NormalDepthPackedTex, uv));

				half NdotL = saturate(dot(N_TS, L_TS));

				half3 diffuse = NdotL * tex.rgb;

				half3 H_TS = normalize(V_TS + L_TS);

				half3 NdotH_TS = max(0.0, dot(N_TS, H_TS));

				half3 specular = pow(NdotH_TS, 22);
				return half4(diffuse + specular, 1);
			}
			ENDHLSL
		}
	}
}
