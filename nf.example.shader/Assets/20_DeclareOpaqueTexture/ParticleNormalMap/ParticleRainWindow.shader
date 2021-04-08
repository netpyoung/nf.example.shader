Shader "ParticleRainWindow"
{
    // ==== for shader
	// ref:
	// - https://blog.naver.com/plasticbag0/221308455834
	// - https://gamedev.stackexchange.com/a/168613
	// - https://80.lv/articles/breakdown-animated-raindrop-material-in-ue4/
	// - [Making a rainy window in Unity - Part 1](https://youtu.be/EBrAdahFtuo)
	
	// ==== for particle
	// ref:
	// - https://blog.naver.com/loveandpic/221315929074
	// - [Unity3D How to : Make Rain (1/2)](https://youtu.be/VN6RzRQ-SWU)
	// 길게흐르기
	// particle system
	//   - renderer > render mode > Streched Billboard
	Properties
	{
		_MainTex("texture", 2D)						= "white" {}
		_NormalPower("_NormalPower", Range(1, 10))	= 1
	}

	SubShader
	{
		Tags
		{
			"RenderPipeline" = "UniversalRenderPipeline"
			"Queue" = "Transparent" // ***
			"RenderType" = "Transparent"
		}

		Pass
		{
			Tags
			{
				"LightMode" = "UniversalForward"
			}

			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off
			ZWrite Off

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl" // SampleSceneColor

			TEXTURE2D(_MainTex);		SAMPLER(sampler_MainTex);

			CBUFFER_START(UnityPerMaterial)
				half4 _MainTex_ST;
				half _NormalPower;
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
				float4 positionNDC      : TEXCOORD3;
			};

			VStoFS vert(APPtoVS IN)
			{
				VStoFS OUT;
				ZERO_INITIALIZE(VStoFS, OUT);

				VertexPositionInputs vertexInputs = GetVertexPositionInputs(IN.positionOS.xyz);

				OUT.positionCS = vertexInputs.positionCS;
				OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

				OUT.positionNDC = vertexInputs.positionNDC;
				return OUT;
			}

			half4 frag(VStoFS IN) : SV_Target
			{
				half3 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;
				half2 dd;
				dd.x = ddx(mainTex.r);
				dd.y = ddy(mainTex.r);
				dd *= _NormalPower;

				half2 screenUV = IN.positionNDC.xy / IN.positionNDC.w;
				half3 sceneColor = SampleSceneColor(screenUV + dd);

				return half4(sceneColor, 1);
			}
			ENDHLSL
		}
	}
}
