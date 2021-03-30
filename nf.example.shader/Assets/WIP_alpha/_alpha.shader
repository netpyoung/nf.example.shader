Shader "_alpha"
{
	Properties
	{
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

			ZWrite On // Default is On.
			Blend SrcAlpha OneMinusSrcAlpha

			HLSLPROGRAM
			#pragma target 3.5

			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			CBUFFER_START(UnityPerObject)
				half _Alpha;
			CBUFFER_END

			struct APPtoVS
			{
				float4 positionOS	: POSITION;
				float4 normal		: NORMAL;
			};

			struct VStoFS
			{
				float4 positionCS	: SV_POSITION;
				float3 N			: TEXCOORD1;
			};

			VStoFS vert(APPtoVS IN)
			{
				VStoFS OUT;
				ZERO_INITIALIZE(VStoFS, OUT);

				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.N = TransformObjectToWorldDir(IN.normal.xyz);
				return OUT;
			}

			half4 frag(VStoFS IN) : SV_Target
			{
				Light light = GetMainLight();
				half3 N = normalize(IN.N);
				half3 L = light.direction;

				half NdotL = dot(N, L);
				if (_Alpha == 0)
				{
					discard;
				}
				return half4(NdotL, NdotL, NdotL, _Alpha);
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
