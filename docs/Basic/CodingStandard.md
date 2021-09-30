# 코딩 스타일

``` hlsl
// 괄호: BSD스타일 - 새행에서 괄호를 열자.
Shader "example/03_texture_uv"
{
    Properties
    {
        // Texture변수는 뒤에 Tex를 붙이자.
        _MainTex("_MainTex",     2D) = "white" {}
        _HeightTex("_HeightTex", 2D) = "gray" {}
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
            // Name: 내부적으로 대문자로 처리되니, 처음부터 대문자로 쓰자.
            Name "HELLO_WORLD"
            
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            // pragma
            // include
            // 변수선언
            // CBUFFER 선언
            // 구조체선언
            // 함수선언(vert / frag)

            #pragma prefer_hlslcc gles // gles is not using HLSLcc by default
            #pragma exclude_renderers d3d11_9x // DirectX 11 9.x는 더 이상 지원되지 않으므로 제외.

            #pragma target 3.5
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // Texture와 sampler는 동일한 라인에 선언해주고, 중간엔 Tab으로 맞추어주자.
            TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
            CBUFFER_END

            // Semantics는 특별히 Tab으로 정렬해주자.
            struct APPtoVS
            {
                float4 positionOS    : POSITION;
                float2 uv            : TEXCOORD0;
            };

            struct VStoFS
            {
                float4 positionCS    : SV_POSITION;
                float2 uv            : TEXCOORD0;
            };

            // vert/frag함수에서 입력/출력에는 IN/OUT을 쓴다.
            VStoFS vert(in APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

                // Time : https://docs.unity3d.com/Manual/SL-UnityShaderVariables.html
                OUT.uv += frac(float2(0, 1) * _Time.x);

                return OUT;
            }

            half4 frag(in VStoFS IN) : SV_Target
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

## 생각해 볼 것

- `L`, `V`
- 일단 흔히 사용되는 방식을 따르고, 좀 더 확신이 들면 바꾸던가 하자

### `NdotL` or `LdotN`

- 어차피 동일한 값이지만 어떤 네이밍을 고를것인가

|       |                         |
|-------|-------------------------|
| NdotL | 흔히 사용(눈에 익음)    |
| LdotN | 주체가 L이라는게 드러남 |

### `L = normalize(light.direction)` or `L = normalize(-light.direction)`

- 유니티의 `light.direction`은 오브젝에서 라이트로 향하는 방향(normalize되지 않은)
  - `light.direction = _MainLightPosition.xyz;`

- postfix붙여볼까?
  - `L_from` , `L_to`

|        |                                 |                                   |
|--------|---------------------------------|-----------------------------------|
| L_to   | L = normalize(light.direction)  | 흔히 사용(눈에 익음)              |
| L_from | L = normalize(-light.direction) | 빛에서 나오는 방향이라는게 들어남 |

|        | LdotN      | R              | H                |
|--------|------------|----------------|------------------|
| L_to   | dot(L, N)  | reflect(-L, N) | normalize(L + V) |
| L_from | dot(-L, N) | reflect(L, N)  | normalize(-L - V) |

#### V?

- 눈(eye)을 뜻하는 E를 쓰는 사람도 있지만... E보다는 V고.. 방향이 문제인데..
- `V = GetWorldSpaceNormalizeViewDir(positionWS);`
  - 오브젝트에서 뷰로 향하는 방향임

``` hlsl
float3 GetViewForwardDir()
{
    float4x4 viewMat = GetWorldToViewMatrix();
    return -viewMat[2].xyz;
}

float3 GetWorldSpaceNormalizeViewDir(float3 positionWS)
{
    if (IsPerspectiveProjection())
    {
        // Perspective
        float3 V = GetCurrentViewPosition() - positionWS;
        return normalize(V);
    }
    else
    {
        // Orthographic
        return -GetViewForwardDir();
    }
}

float3 GetPrimaryCameraPosition()
{
#if (SHADEROPTIONS_CAMERA_RELATIVE_RENDERING != 0)
    return float3(0, 0, 0);
#else
    return _WorldSpaceCameraPos;
#endif
}

// Could be e.g. the position of a primary camera or a shadow-casting light.
float3 GetCurrentViewPosition()
{
#if defined(SHADERPASS) && (SHADERPASS != SHADERPASS_SHADOWS)
    return GetPrimaryCameraPosition();
#else
    // This is a generic solution.
    // However, for the primary camera, using '_WorldSpaceCameraPos' is better for cache locality,
    // and in case we enable camera-relative rendering, we can statically set the position is 0.
    return UNITY_MATRIX_I_V._14_24_34;
#endif
}
```
