Shader "n18Approximation"
{
	// ref: https://www.gamasutra.com/view/feature/131381/a_noninteger_power_function_on_.php
	Properties
	{
		[Toggle(ENABLE_APPROXIMATION)]
		_EnableApproximation("Enable Approximation", Float) = 0

		_n("n", Float) = 18
		_m("m", Float) = 2
		_A("A", Float) = 6.645
		_B("B", Float) = -5.645
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
			Name "N18_APPROXIMATION"

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
			#pragma shader_feature_local ENABLE_APPROXIMATION

			half _n;
			half _m;
			half _A;
			half _B;

			struct APPtoVS
			{
				float4 positionOS	: POSITION;
				float3 normalOS     : NORMAL;
			};

			struct VStoFS
			{
				float4 positionCS	: SV_POSITION;

				float3 N            : TEXCOORD1;
				float3 V            : TEXCOORD2;
				float3 L            : TEXCOORD3;
			};

			VStoFS vert(APPtoVS IN)
			{
				VStoFS OUT;
				ZERO_INITIALIZE(VStoFS, OUT);

				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);

				Light light = GetMainLight();
				OUT.N = TransformObjectToWorldNormal(IN.normalOS);
				OUT.V = normalize(GetWorldSpaceViewDir(TransformObjectToWorld(IN.positionOS.xyz)));
				OUT.L = normalize(light.direction);
				return OUT;
			}

			inline half n18Approximation(half x)
			{
				// n | 18
				// m | 2
				//     pow(x, n)
				//     pow(x, 18)
				//     pow(max(0, Ax        + B     ), m)
				return pow(max(0, 6.645 * x + -5.645), 2);
			}

			inline half Approximation(half x)
			{
				return pow(max(0, _A * x + _B), _m);
			}

			half4 frag(VStoFS IN) : SV_Target
			{
				half3 N = normalize(IN.N);
				half3 V = normalize(IN.V);
				half3 L = normalize(IN.L);

				half3 R = reflect(-L, N);

				half3 diffuseColor = max(0, dot(N, L));

#if ENABLE_APPROXIMATION
				// half3 specularColor = n18Approximation(max(0, dot(R, V)));
				half3 specularColor = Approximation(max(0, dot(R, V)));
				
#else
				// half3 specularColor = pow(max(0, dot(R, V)), 18);
				half3 specularColor = pow(max(0, dot(R, V)), _n);
#endif

				half3 finalColor = diffuseColor + specularColor;
				return half4(finalColor, 1);
			}
			ENDHLSL
		}
	}
}
