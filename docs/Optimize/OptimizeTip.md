# Optimize tip

## from [Optimizing unity games (Google IO 2014)](https://www.slideshare.net/AlexanderDolbilov/google-i-o-2014)

- Shader.SetGlobalVector
- OnWillRenderObject(오브젝트가 보일때만), propertyID(string보다 빠름)

``` cs
void OnWillRenderObject()
{
    material.SetMatrix(propertyID, matrix);
}
```

## Tangent Space 라이트 계산

- 월드 스페이스에서 라이트 계산값과 탄젠트 스페이스에서 라이트 계산값과 동일.
- vertex함수에서 tangent space V, L을 구하고 fragment함수에 넘겨줌.
  - 월드 스페이스로 변환 후 계산하는 작업을 단축 할 수 있음

## 데미지폰트

- 셰이더로 한꺼번에 출력
- <https://blog.naver.com/jinwish/221577786406>

## NPOT 지원안하는 텍스쳐 포맷

- NPOT지원안하는 ETC/PVRTC같은경우 POT로 자르고 셰이더로 붙여주는걸 작성해서 최적화
  - <https://blog.naver.com/jinwish/221576705990>

## GGX 공식 간략화

- Optimizing PBR for Mobile
  - [pdf](https://community.arm.com/cfs-file/__key/communityserver-blogs-components-weblogfiles/00-00-00-20-66/siggraph2015_2D00_mmg_2D00_renaldas_2D00_slides.pdf), [note](https://community.arm.com/cfs-file/__key/communityserver-blogs-components-weblogfiles/00-00-00-20-66/siggraph2015_2D00_mmg_2D00_renaldas_2D00_notes.pdf)

## 밉맵 디테일 올리기

### 샤픈

- <https://blog.popekim.com/ko/2013/06/24/mipmap-quality.html>
- <https://zhuanlan.zhihu.com/p/413834301>

## FAST SRGB

- pow에 계산되는 비용을 줄이기 위한 방법
- ShaderFeatures.UseFastSRGBLinearConversion 
- [sRGB Approximations for HLSL](http://chilliant.blogspot.com/2012/08/srgb-approximations-for-hlsl.html)

``` hlsl
// com.unity.postprocessing/PostProcessing/Shaders/Colors.hlsl
half3 SRGBToLinear(half3 c)
{
#if USE_VERY_FAST_SRGB
    return c * c;
#elif USE_FAST_SRGB
    return c * (c * (c * 0.305306011 + 0.682171111) + 0.012522878);
#else
    half3 linearRGBLo = c / 12.92;
    half3 linearRGBHi = PositivePow((c + 0.055) / 1.055, half3(2.4, 2.4, 2.4));
    half3 linearRGB = (c <= 0.04045) ? linearRGBLo : linearRGBHi;
    return linearRGB;
#endif
}

half3 LinearToSRGB(half3 c)
{
#if USE_VERY_FAST_SRGB
    return sqrt(c);
#elif USE_FAST_SRGB
    return max(1.055 * PositivePow(c, 0.416666667) - 0.055, 0.0);
#else
    half3 sRGBLo = c * 12.92;
    half3 sRGBHi = (PositivePow(c, half3(1.0 / 2.4, 1.0 / 2.4, 1.0 / 2.4)) * 1.055) - 0.055;
    half3 sRGB = (c <= 0.0031308) ? sRGBLo : sRGBHi;
    return sRGB;
#endif
}

// com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl
float3 PositivePow(float3 base, float3 power)
{
    return pow(max(abs(base), float3(FLT_EPSILON, FLT_EPSILON, FLT_EPSILON)), power);
}
```
