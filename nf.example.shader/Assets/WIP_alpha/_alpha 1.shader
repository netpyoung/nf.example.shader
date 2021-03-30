Shader "_alpha1"
{
	Properties
	{
		_MainTex("texture", 2D) = "white" {}
		_Alpha("Alpha", Range(0, 1)) = 0.5
	}

	SubShader
	{
		Tags
		{
			"RenderPipeline" = "UniversalRenderPipeline"
		}

		Pass
		{
			Name "RED_CIRCLE"

			Tags
			{
				"LightMode" = "UniversalForward"
				"Queue" = "Transparent"
				"RenderType" = "Transparent"
			}

			Cull Off
			ZWrite On // Default is On.
			Blend SrcAlpha OneMinusSrcAlpha

			HLSLPROGRAM
			#pragma target 3.5

			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			TEXTURE2D(_MainTex);		SAMPLER(sampler_MainTex);

			CBUFFER_START(UnityPerMaterial)
				float4 _MainTex_ST;
				half _Alpha;
			CBUFFER_END

			struct APPtoVS
			{
				float4 positionOS	: POSITION;
				float4 normal		: NORMAL;
				float2 uv			: TEXCOORD0;
			};

			struct VStoFS
			{
				float4 positionCS	: SV_POSITION;
				float2 uv			: TEXCOORD0;
				float3 N			: TEXCOORD1;
			};

			VStoFS vert(APPtoVS IN)
			{
				VStoFS OUT;
				ZERO_INITIALIZE(VStoFS, OUT);

				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.N = TransformObjectToWorldDir(IN.normal.xyz);
				OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

				return OUT;
			}

			half4 frag(VStoFS IN) : SV_Target
			{
				half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv) * _Alpha;
				if (mainTex.a == 0)
				{
					discard;
				}
				return mainTex;
			}
			ENDHLSL
		}

		Pass
		{
			// https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl

			Name "DEPTHONLY"

			Tags
			{
				"LightMode" = "DepthOnly"
				"Queue" = "Transparent"
				"RenderType" = "Transparent"
			}

			HLSLPROGRAM
			#pragma target 3.5

			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			TEXTURE2D(_BaseMap);            SAMPLER(sampler_BaseMap);
			
			CBUFFER_START(UnityPerMaterial)
				float4 _BaseMap_ST;
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
				OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);

				return OUT;
			}

			half4 frag(VStoFS IN) : SV_Target
			{
				return 0;
			}
			ENDHLSL
		}
	}
}
