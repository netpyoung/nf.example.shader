# 코딩 스타일

``` hlsl
// 괄호: BSD스타일 - 새행에서 괄호를 열자.
Shader "example/03_texture_uv"
{
	Properties
	{
		// Texture변수는 뒤에 Tex를 붙이자.
		_MainTex("texture", 2D) = "white"
	}

	SubShader
	{
		// SubShader의 Tag: 공통인 RenderPipeline를 놔두자
		Tags
		{
			"RenderPipeline" = "UniversalRenderPipeline"
		}

		Pass
		{
			// Name: 내부적으로 대문자로 처리되니, 처음부터 대문자로 쓰자.
			Name "HELLO_WORLD"
			
			// Pass의 Tags: 사용빈도 순으로 통일시키겠다.
			// LightMode > Queue > RenderType
			Tags
			{
				"LightMode" = "UniversalForward"
				"Queue" = "Geometry"
				"RenderType" = "Opaque"
			}

			HLSLPROGRAM
			// pragma
			// include
			// 변수선언
			// CBUFFER 선언
			// 구조체선언
			// 함수선언(vert / frag)
			
			#pragma target 3.5
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			// Texture와 sampler는 동일한 라인에 선언해주고, 중간엔 Tab으로 맞추어주자.
			TEXTURE2D(_MainTex);		SAMPLER(sampler_MainTex);

			CBUFFER_START(UnityPerMaterial)
				float4 _MainTex_ST;
			CBUFFER_END

			// Semantics는 특별히 Tab으로 정렬해주자.
			struct Attributes
			{
				float4 positionOS	: POSITION;
				float2 uv			: TEXCOORD0;

			};

			struct Varyings
			{
				float4 positionHCS	: SV_POSITION;
				float2 uv			: TEXCOORD0;
			};

			// vert/frag함수에서 입력/출력에는 IN/OUT을 쓴다.
			Varyings vert(Attributes IN)
			{
				Varyings OUT;
				ZERO_INITIALIZE(Varyings, OUT);

				OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

				// Time : https://docs.unity3d.com/Manual/SL-UnityShaderVariables.html
				OUT.uv += frac(float2(0, 1) * _Time.x);

				return OUT;
			}

			half4 frag(Varyings IN) : SV_Target
			{
				// if / for등 괄호({, })를 빼먹지 말자.
				if (...)
				{
					...
				}
				return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
			}
			ENDHLSL
		}
	}
}
```

``` hlsl
// mainTex - _MainTex 이름 맞추기.
half3 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;
half3 normalTex = UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, IN.uv));

// 월드스페이스 방향. 대문자로.
Light light = GetMainLight();
half3 T = normalize(IN.B);
half3 N = CombineTBN(normalTex, IN.T, IN.B, IN.N);
half3 L = normalize(light.direction);
half3 V = TransformWorldToViewDir(IN.positionWS);
half3 H = normalize(L + V);

// dot연산 변수는 NdotL과 같은 형식으로
half NdotL = max(0.0, dot(N, L));
half TdotL = dot(T, L);
half TdotV = dot(T, V);

// 나머지 함수 연산은 sinTL 이런식으로.
half sinTL = sqrt(1 - TdotL * TdotL);
```