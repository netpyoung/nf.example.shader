
- [실시간 그림자를 싸게 그리자! 평면상의 그림자 ( Planar Shadow for Skinned Mesh)](http://ozlael.egloos.com/4070775)


- 원형(circle) 평면 그림자
- 그림자용 카메라(렌더타겟텍스쳐) + 쉐도우용 모델(폴리곤 적은)
- 쉐이더볼륨
- 쉐이더맵

### Shadow
아 유니티 병신같은 문서어딧


[URP 셰이더 코딩 튜토리얼 : 제 1편 - Unlit Soft Shadow](https://blog.naver.com/mnpshino/221844164319)

[URP Default Unlit Based to Custom Lighting](https://illu.tistory.com/1407)
[urp管线的自学hlsl之路 第十篇 主光源阴影投射和接收](https://www.bilibili.com/read/cv6436088/)
[builtin -  Rendering 7 Shadows](https://catlikecoding.com/unity/tutorials/rendering/part-7/)

[[Unity] URP Custom Shadow Shader 도전하기 : Frame Debugger로 원인 찾기(1/3)](https://tmdcks2368.medium.com/unity-urp-custom-shadow-shader-%EB%8F%84%EC%A0%84%ED%95%98%EA%B8%B0-%EB%AC%B8%EC%A0%9C%ED%8E%B8-1-3-e8e7f74c192a)
[[Unity] URP Custom Shadow Shader 도전하기 : Frame Debugger로 원인 찾기(2/3)](https://tmdcks2368.medium.com/unity-urp-custom-shadow-shader-%EB%8F%84%EC%A0%84%ED%95%98%EA%B8%B0-%EC%BD%94%EB%93%9C-%EB%94%B0%EB%9D%BC%EA%B0%80%EB%A9%B0-%EB%AC%B8%EC%A0%9C-%EC%9B%90%EC%9D%B8-%EC%B0%BE%EA%B8%B0-2-3-5831e340d8eb)
[[Unity] URP Custom Shadow Shader 도전하기 : Frame Debugger로 원인 찾기(3/3)](https://tmdcks2368.medium.com/unity-urp-custom-shadow-shader-%EB%8F%84%EC%A0%84%ED%95%98%EA%B8%B0-frame-debugger%EB%A1%9C-%EC%9B%90%EC%9D%B8-%EC%B0%BE%EA%B8%B0-3-3-bae7825480d3)
[Reading a depth value from Unity's shadow map?](https://forum.unity.com/threads/reading-a-depth-value-from-unitys-shadow-map.243092/)


// Toggle the alpha test
#define _ALPHATEST_ON

// Toggle fog on transparent
#define _ENABLE_FOG_ON_TRANSPARENT

``` hlsl
UnityEngine.Rendering.Universal.ShaderKeywordStrings

// Light & Shadow
#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
#pragma multi_compile _ _ADDITIONAL_LIGHTS
#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
#pragma multi_compile _ _SHADOWS_SOFT


o.shadowCoord = GetShadowCoord(vertexInput);

float4 shadowCoord = TransformWorldToShadowCoord(positionWorldSpace);
Light mainLight = GetMainLight(inputData.shadowCoord);
half shadow = mainLight.shadowAttenuation;
finalColor.rgb *= shadow;

UsePass "Universal Render Pipeline/Lit/ShadowCaster"

com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl

// You can also optionally disable shadow receiving for transparent to improve performance. To do so, disable Transparent Receive Shadows in the Forward Renderer asset
_MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN ?? => MAIN_LIGHT_CALCULATE_SHADOWS
_MAIN_LIGHT_SHADOWS_CASCADE => REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
_ADDITIONAL_LIGHT_SHADOWS => ADDITIONAL_LIGHT_CALCULATE_SHADOWS

// cascade
// https://forum.unity.com/threads/what-does-shadows_screen-mean.568225/
// https://forum.unity.com/threads/water-shader-graph-transparency-and-shadows-universal-render-pipeline-order.748142/

PipelineAsset> Shadows > Cascades> No Cascades
```

``` hlsl
// 그림자 그려주는놈

Name "ShadowCaster"
Tags{"LightMode" = "ShadowCaster"}
ZWrite On
Cull Back

vert()
{
    1 : lit
    0 : shadow
    return 1 or 0;
}
```
![./urp_shader_res/cascade.jpg](./urp_shader_res/cascade.jpg)

``` hlsl
// com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl
#if !defined(_RECEIVE_SHADOWS_OFF)
    #if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) || defined(_MAIN_LIGHT_SHADOWS_SCREEN)
        #define MAIN_LIGHT_CALCULATE_SHADOWS

        #if !defined(_MAIN_LIGHT_SHADOWS_CASCADE)
            #define REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
        #endif
    #endif

    #if defined(_ADDITIONAL_LIGHT_SHADOWS)
        #define ADDITIONAL_LIGHT_CALCULATE_SHADOWS
    #endif
#endif

TEXTURE2D_SHADOW(_MainLightShadowmapTexture);
SAMPLER_CMP(sampler_MainLightShadowmapTexture);

half4       _MainLightShadowParams;   // (x: shadowStrength, y: 1.0 if soft shadows, 0.0 otherwise, z: main light fade scale, w: main light fade bias)
float4      _MainLightShadowmapSize;  // (xy: 1/width and 1/height, zw: width and height)

struct ShadowSamplingData
{
    half4 shadowOffset0;
    half4 shadowOffset1;
    half4 shadowOffset2;
    half4 shadowOffset3;
    float4 shadowmapSize;
};

// ShadowParams
// x: ShadowStrength
// y: 1.0 if shadow is soft, 0.0 otherwise
half4 GetMainLightShadowParams()
{
    return _MainLightShadowParams;
}

half MainLightRealtimeShadow(float4 shadowCoord)
    ShadowSamplingData shadowSamplingData = GetMainLightShadowSamplingData();
    half4 shadowParams = GetMainLightShadowParams();
    return SampleShadowmap(TEXTURE2D_ARGS(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture), shadowCoord, shadowSamplingData, shadowParams, false);

half AdditionalLightRealtimeShadow(int lightIndex, float3 positionWS, half3 lightDirection)
real SampleShadowmap(TEXTURE2D_SHADOW_PARAM(ShadowMap, sampler_ShadowMap), float4 shadowCoord, ShadowSamplingData samplingData, half4 shadowParams, bool isPerspectiveProjection = true) _SHADOWS_SOFT

PipelineAsset> Shadows > Cascades> Soft Shadows

_SHADOWS_SOFT : real SampleShadowmapFiltered(TEXTURE2D_SHADOW_PARAM(ShadowMap, sampler_ShadowMap), float4 shadowCoord, ShadowSamplingData samplingData)
float4 TransformWorldToShadowCoord(float3 positionWS)  : _MAIN_LIGHT_SHADOWS_CASCADE
_MAIN_LIGHT_SHADOWS_CASCADE : half ComputeCascadeIndex(float3 positionWS)


float3 ApplyShadowBias(float3 positionWS, float3 normalWS, float3 lightDirection)

LerpWhiteTo
```


``` hlsl
#pragma multi_compile_fog
OUT.fogCoord = ComputeFogFactor(OUT.positonHCS.z);

half3 ambient = SampleSH(IN.N);
finalColor.rgb *= ambient;
finalColor.rgb = MixFog(finalColor.rgb, IN.fogCoord);
```

## ShadowAttenuation

``` hlsl
// URP
half4 shadowCoord = TransformWorldToShadowCoord(positionWS);
// or
// VertexPositionInputs vertexInput = GetVertexPositionInputs(IN.positionOS.xyz);
// half4 shadowCoord = GetShadowCoord(vertexInput);

half shadowAttenuation = MainLightRealtimeShadow(shadowCoord);
// or
// ShadowSamplingData shadowSamplingData = GetMainLightShadowSamplingData();
// half4 shadowParams = GetMainLightShadowParams();
// half shadowAttenuation = SampleShadowmap(TEXTURE2D_ARGS(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture), shadowCoord, shadowSamplingData, shadowParams, false);
// or
// Light mainLight = GetMainLight(i.shadowCoord);
// half shadowAttenuation = mainLight.shadowAttenuation;
```


## ShadowCaster

``` hlsl
Pass
{
    Name "ShadowCaster"
    Tags
    {
        "LightMode" = "ShadowCaster"
    }

    ZWrite On
    Cull Back

    HLSLPROGRAM
    #pragma target 3.5

    #pragma vertex shadowVert
    #pragma fragment shadowFrag

    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"  // real
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl" // LerpWhiteTo
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl" // ApplyShadowBias

    struct Attributes
    {
        float4 positionOS   : POSITION;
        float4 normal       : NORMAL;
    };

    struct Varyings
    {
        float4 positionHCS  : SV_POSITION;
    };

    Varyings shadowVert(Attributes IN)
    {
        Varyings OUT = (Varyings)0;

        float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
        float3 normalWS = TransformObjectToWorldNormal(IN.normal.xyz);
        OUT.positionHCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _MainLightPosition.xyz));

        return OUT;
    }

    half4 shadowFrag(Varyings IN) : SV_Target
    {
        return 0;
    }
    ENDHLSL
}
```

``` hlsl
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"  // real
#if defined(SHADER_API_MOBILE) || defined(SHADER_API_SWITCH)
#define HAS_HALF 1
#else
#define HAS_HALF 0
#endif

#if REAL_IS_HALF
#define real half
#define real2 half2
#define real3 half3
#define real4 half4

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl" // ApplyShadowBias
float3 ApplyShadowBias(float3 positionWS, float3 normalWS, float3 lightDirection)


real SampleShadowmap(TEXTURE2D_SHADOW_PARAM(ShadowMap, sampler_ShadowMap), float4 shadowCoord, ShadowSamplingData samplingData, half4 shadowParams, bool isPerspectiveProjection = true)
// 안쓰는 놈인데.. LerpWhiteTo를 들고있다..

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl" // LerpWhiteTo
real LerpWhiteTo(real b, real t)
```



## 쉐도우맵

1. Z-depth구하기
   1. 씬 렌더링
   2. Z-depth를 깊이버퍼에 저장한다(depth map)

      ``` txt
      world > View[Light] > Proj[Light]
            Light's View Matrix > Light's Projection Matrix
      > transform NDC
      > transform texture Space
      ```

2. 그림자그리기
   1. 씬 렌더링
   2. 깊이버퍼랑 Z-depth 테스트

      ``` txt
      if (fragment Z-depth > sampled Z-depth)
      {
          shadow : 0
      }
      else
      {
          lit     : 1
      }


##
- SSSM(Screen Space Shadow Map)


- [Unity Shader - Custom SSSM(Screen Space Shadow Map) 自定义屏幕空间阴影图](https://blog.csdn.net/linjf520/article/details/105456097)
- [OpenGL - 阴影映射 - Tutorial 16 : Shadow mapping](https://blog.csdn.net/linjf520/article/details/105380551)

### Shadow Acne