Shader "example/02_texture"
{
	Properties
	{
		_MainTex("texture", 2D) = "white" {}
		[HDR] _HexColor("_HexColor", Color) = (0, 0.3, 1, 1)
		_FresnelPower("_FresnelPower", Float) = 40

		[HDR] _IntersectColor("_IntersectColor", Color) = (1, 0, 0, 1)
		_IntersectIntensity("Intersection Intensity", Float) = 30
		_IntersectExponent("Intersection Falloff Exponent", Float) = 5

		_PointPosition("_PointPosition", Vector) = (0, 1, -1, 0)
		[HDR] _MaskColor("_MaskColor", Color) = (1, 1, 0, 1)
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

			Blend SrcAlpha OneMinusSrcAlpha
			Cull back
			ZWrite Off

			HLSLPROGRAM
			#pragma target 3.5

			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl" // SampleSceneColor

			TEXTURE2D(_MainTex);	SAMPLER(sampler_MainTex);

			CBUFFER_START(UnityPerMaterial)
				float4 _MainTex_ST;
				half3 _HexColor;
				half _FresnelPower;

				half3 _IntersectColor;
				half _IntersectIntensity;
				half _IntersectExponent;

				half3 _PointPosition;
				half3 _MaskColor;
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
				float2 uv			: TEXCOORD0;
				float3 N			: TEXCOORD3;
				float3 positionWS	: TEXCOORD4;
				float4 positionNDC	: TEXCOORD5;

			};
			
			VStoFS vert(APPtoVS IN)
			{
				VStoFS OUT;
				ZERO_INITIALIZE(VStoFS, OUT);

				half3 positionOS = IN.positionOS.xyz;
				
				positionOS += abs(sin(_Time.y * 2)) * (IN.normalOS * 0.002);

				VertexPositionInputs vertexInputs = GetVertexPositionInputs(positionOS);

				OUT.positionCS = vertexInputs.positionCS;
				OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
				OUT.N = TransformObjectToWorldNormal(IN.normalOS);
				OUT.positionWS = vertexInputs.positionWS;
				OUT.positionNDC = vertexInputs.positionNDC;

				return OUT;
			}

			half4 frag(VStoFS IN) : SV_Target
			{
				half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);

				Light light = GetMainLight();
				half3 L = normalize(light.direction);
				half3 V = GetWorldSpaceNormalizeViewDir(IN.positionWS);
				half3 N = normalize(IN.N);
				half fresnel = pow(1.0 - saturate(dot(N, V)), 5);
				// return half4(fresnel, fresnel, fresnel, 1);


				// InterSection
				half2 screenUV = IN.positionNDC.xy / IN.positionNDC.w;
				half sceneZ = LinearEyeDepth(SampleSceneDepth(screenUV), _ZBufferParams);
				half partZ = IN.positionNDC.w;
				half depth = sceneZ - partZ;
				half intersectGradient = 1 - min(depth, 1.0f);
				half3 intersectTerm = _IntersectColor.rgb * pow(intersectGradient, _IntersectExponent) * _IntersectIntensity;
				// return half4(intersectTerm, intersectGradient);

				half3 screenColor = SampleSceneColor(screenUV);
				// return half4(screenColor, 1);

				half NdotL = dot(N, L);

				// return half4(fresnel * mainTex.rgb, 1);

				
				

				// half3 finalColor = screenColor + fresnel * _FresnelColor * mainTex * _HexColor + intersectTerm;
				half3 finalColor = screenColor + fresnel * _FresnelPower * mainTex.rgb * _HexColor + intersectTerm;

				half mask = 1 - saturate((distance(IN.positionWS, _PointPosition) - 0.01) / (1 - 0.4));
				// return half4(mask, mask, mask, 1);
				finalColor += mask * _MaskColor;

				return half4(finalColor, mainTex.a);
			}
			ENDHLSL
		}
	}
}
