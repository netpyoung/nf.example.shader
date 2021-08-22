# Eye Adaptation / Luminance Adaptation / Auto Exposure

- 광적응
  - 현재밝기와 이전밝기를 이용하여 적절한밝기를 구하고, 이를 원본 이미지에 적용한다.

## Overview

1. 현재밝기
   - 현재 화면의 평균밝기 저장(사이즈를 줄여가며 1x1텍스쳐로)
   - 휘도 전용, POT(Power of Two), Mipmap 적용(1x1용), R16 색이면 충분.
2. 적절한밝기
   - 이전화면 평균밝기와 비교해서 적절한 밝기 얻기
3. 적절한밝기 적용
   - 앞서구한 적절한 밝기를 원본 이미지에 적용
4. 이전밝기
   - 적절한밝기를 이전밝기에 저장

## 예제코드

``` hlsl
// https://en.wikipedia.org/wiki/Relative_luminance
// https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl
real Luminance(real3 linearRgb)
{
    return dot(linearRgb, real3(0.2126729, 0.7151522, 0.0721750));
}
```

``` hlsl
간상체T_robs  약 0.2
추상체T_cones 약 0.4

r = p * T_robs + (1 - p) * T_cones

float SensitivityOfRods(float y)
{
   return 0.04 / (0.04 + y);
}
```

```hlsl
half middleGray = 1.03 - (2 / (2 + log10(lumaAverageCurr + 1)));
half lumaScaled = (lumCurr * middleGrey) / lumaAverageCurr;

half lumaAdaptCurr = lumaAdaptedPrev + (lumaAverageCurr - lumaAdaptedPrev) * (1 - exp(- (dt) / AdaptationConstatnt));
// half sensitivity = SensitivityOfRod(luma)
half lumaAdaptCurr = lumaAdaptedPrev + (lumaAverageCurr - lumaAdaptedPrev) * (1 - exp( -(dt) / sensitivity * _FrameSpeed));
```

``` hlsl
///  ref: Programming Vertex Geometry and Pixel Shaders : High-Dynamic Range Rendering
float lumaScaled = Yxy.r * MiddleGray / (AdaptedLum.x + 0.001f);
Yxy.r = (lumaScaled * (1.0f + lumaScaled / White))/(1.0f + lumaScaled);
```

``` hlsl
AutoKey = saturate(1.5 - (1.5 / (lumaAverageCurr * 0.1 + 1))) + 0.1; 


Color *= Key / (lumaAdaptCurr + 0.0001f);
Color = ToneMap(Color);

/// ref: 2007 Realtime HDR Rendering - Christian Luksch = 13.4. Adaptive Logarithmic Mapping
// _B = 0.5 and 1 
Color = Key
       / log10(lumaAverageCurr + 1)
       * log(Color + 1)
       / log(2 + pow((Color / lumaAverageCurr), log(_B) / log(0.5)) * 8);
```

``` hlsl
/// ref: Perceptual Eects in Real-time Tone Mapping
lumaToned = ToneMap(luma);
rgbL = rgb * (lumaToned * (1 - s)) / luma + (1.05, 0.97, 1.27) * lumaToned * s;
```

## Ref

- [GDC2006 - Hdr Meets Black And White 2](https://www.slideshare.net/fcarucci/HDR-Meets-Black-And-White-2-2006)
- [canny708 - Eye Adaptation (Automatic Exposure)](https://blog.naver.com/canny708/221892561143)
- [HDRToneMappingCS11](https://github.com/walbourn/directx-sdk-samples/tree/master/HDRToneMappingCS11)
- [Reverse engineering the rendering of The Witcher 3, part 2 - eye adaptation](https://astralcode.blogspot.com/2017/10/reverse-engineering-rendering-of.html)
- <https://github.com/przemyslawzaworski/Unity3D-CG-programming/tree/master/HDR>
- <http://developer.download.nvidia.com/SDK/9.5/Samples/samples.html>
  - <http://developer.download.nvidia.com/SDK/9.5/Samples/DEMOS/Direct3D9/DeferredShading.zip>
- Programming Vertex Geometry and Pixel Shaders : Range Mapping, Light Adaptation
- <https://www.cg.tuwien.ac.at/research/publications/2007/Luksch_2007_RHR/>
- <https://knarkowicz.wordpress.com/2016/01/09/automatic-exposure/>
