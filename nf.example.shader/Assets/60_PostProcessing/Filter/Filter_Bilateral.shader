Shader "Filter/Bilateral"
{
	Properties
	{
		[NoScaleOffset] _MainTex("texture", 2D) = "white" {}
		_Sigma("_Sigma", Range(0.001, 2.0)) = 0.7
		[Toggle(IS_BLUR)]_IsBlur("Apply Blur?", Float) = 1

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
			Name "FILTER_BILATERAL"

			Tags
			{
				"LightMode" = "UniversalForward"
			}

			HLSLPROGRAM
			#pragma target 3.5

			#pragma vertex vert
			#pragma fragment frag
			#pragma shader_feature_local _ IS_BLUR

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			TEXTURE2D(_MainTex);	SAMPLER(sampler_MainTex);
	
			CBUFFER_START(UnityPerMaterial)
				float2 _MainTex_TexelSize;
				half _Sigma;
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
				OUT.uv = IN.uv;
				
				return OUT;
			}

			half Gauss(half d, half sigma)
			{
				return 1.0 / (sigma * sqrt(2.0 * 3.14)) * exp((-d * d) / (2.0 * sigma * sigma));
			}

			half4 frag(VStoFS IN) : SV_Target
			{
#if IS_BLUR
				half3 accColor = half3(0.0, 0.0, 0.0);
				half accWeight = 0;
				for (int y = -1; y <= 1; ++y)
				{
					for (int x = -1; x <= 1; ++x)
					{
						half2 uv = IN.uv + _MainTex_TexelSize.xy * half2(x, y);
						half3 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv).rgb;
						half weight = Gauss(length((IN.uv - uv) / _MainTex_TexelSize.xy), _Sigma);
						accColor += mainTex * weight;
						accWeight += weight;
					}
				}
				
				accColor /= accWeight;

				return half4(accColor, 1);
#else
				return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
#endif
			}
			ENDHLSL
		}
	}
}
