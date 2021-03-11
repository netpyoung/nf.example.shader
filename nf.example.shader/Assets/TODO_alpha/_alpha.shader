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
				"Queue" = "AlphaTest"
				"RenderType" = "TransparentCutout"
			}

			Cull Off

			HLSLPROGRAM
			#pragma target 3.5

			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			CBUFFER_START(UnityPerObject)
				half _Alpha;
			CBUFFER_END

			struct Attributes
			{
				float4 positionOS	: POSITION;
				float4 normal		: NORMAL;
			};

			struct Varyings
			{
				float4 positionHCS	: SV_POSITION;
				float3 N			: TEXCOORD1;
			};

			Varyings vert(Attributes IN)
			{
				Varyings OUT;
				ZERO_INITIALIZE(Varyings, OUT);

				OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.N = TransformObjectToWorldDir(IN.normal.xyz);
				return OUT;
			}

			half4 frag(Varyings IN) : SV_Target
			{
				Light light = GetMainLight();
				half3 N = normalize(IN.N);
				half3 L = light.direction;

				half NdotL = dot(N, L);

				return half4(NdotL, NdotL, NdotL, _Alpha);
			}
			ENDHLSL
		}
	}
}
