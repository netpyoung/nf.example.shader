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
			//ZWrite Off
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

			struct Attributes
			{
				float4 positionOS	: POSITION;
				float4 normal		: NORMAL;
				float2 uv			: TEXCOORD0;

			};

			struct Varyings
			{
				float4 positionHCS	: SV_POSITION;
				float2 uv			: TEXCOORD0;
				float3 N			: TEXCOORD1;
			};

			Varyings vert(Attributes IN)
			{
				Varyings OUT;
				ZERO_INITIALIZE(Varyings, OUT);

				OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.N = TransformObjectToWorldDir(IN.normal.xyz);
				OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

				return OUT;
			}

			half4 frag(Varyings IN) : SV_Target
			{
				half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
				// clip(mainTex.a - 0.1);
				return mainTex;
			}
			ENDHLSL
		}

		//Pass
		//{
		//	Tags{"LightMode" = "DepthOnly"}

		//	ZWrite On
		//	ColorMask 0

		//	HLSLPROGRAM
		//	#pragma target 3.5

		//	#pragma vertex DepthOnlyVertex
		//	#pragma fragment DepthOnlyFragment

		//	// -------------------------------------
		//	// Material Keywords
		//	#pragma shader_feature _ALPHATEST_ON

		//	//--------------------------------------
		//	// GPU Instancing
		//	#pragma multi_compile_instancing

		//	#include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitInput.hlsl"
		//	#include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
		//	ENDHLSL
		//}
	}
}
