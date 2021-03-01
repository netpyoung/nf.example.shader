Shader "PlanarShadow" 
{
	// ref:
	// 실시간 그림자를 싸게 그리자! 평면상의 그림자 ( Planar Shadow for Skinned Mesh) 
	//   - https://ozlael.tistory.com/10
	//   - https://github.com/ozlael/PlannarShadowForUnity

	Properties {
		_ShadowColor ("Shadow Color", Color) = (0, 0, 0, 1)
		_PlaneHeight ("planeHeight", Float) = 0
	}

	SubShader
	{
		Pass
		{   
			Tags
			{
				"Queue"="Transparent"
				"IgnoreProjector"="True"
				"RenderType"="Transparent"
				"RenderPipeline" = "UniversalRenderPipeline"
			}

			ZWrite On
			ZTest LEqual 
			Blend SrcAlpha OneMinusSrcAlpha

			Stencil
			{
				Ref 0
				Comp Equal
				Pass IncrWrap
				ZFail Keep
			}

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			CBUFFER_START(UnityPerMaterial)
				half4 _ShadowColor;
				half _PlaneHeight;
			CBUFFER_END

			struct Attributes
			{
				float4 positionOS : POSITION;
			};

			struct Varyings
			{
				float4 positionHCS : SV_POSITION;
			};

			Varyings vert(Attributes IN)
			{
				Varyings OUT = (Varyings)0;

				Light light = GetMainLight();
				half3 L = light.direction;

				half3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
				half opposite = positionWS.y - _PlaneHeight;
				half cosTheta = -L.y;
				half hypotenuse = opposite / cosTheta;

				positionWS += (L * hypotenuse);
				positionWS.y = _PlaneHeight;

				OUT.positionHCS = TransformWorldToHClip(positionWS);
				return OUT;
			}

			half4 frag(Varyings IN) : SV_Target
			{
				return _ShadowColor;
			}
			ENDHLSL
		}
	}
}
