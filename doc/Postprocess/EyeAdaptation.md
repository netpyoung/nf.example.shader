# Eye Adaptation / Luminance Adaptation / Auto Exposure

- 광적응
  - 현재밝기와 이전밝기를 이용하여 적절한밝기를 구하고, 이를 원본 이미지에 적용한다.

``` hlsl
// https://en.wikipedia.org/wiki/Relative_luminance
// https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl
real Luminance(real3 linearRgb)
{
    return dot(linearRgb, real3(0.2126729, 0.7151522, 0.0721750));
}
```

1. 현재밝기
   - 현재 화면의 평균밝기 저장(사이즈를 줄여가며 1x1텍스쳐로)
   - 휘도 전용, POT(Power of Two), Mipmap 적용(1x1용), R16 색이면 충분.
2. 적절한밝기
   - 이전화면 평균밝기와 비교해서 적절한 밝기 얻기
3. 이전밝기
   - 앞서구한 적절한 밝기를 원본 이미지에 적용

- [GDC2006 - Hdr Meets Black And White 2](https://www.slideshare.net/fcarucci/HDR-Meets-Black-And-White-2-2006)
- [canny708 - Eye Adaptation (Automatic Exposure)](https://blog.naver.com/canny708/221892561143)
- [HDRToneMappingCS11](https://github.com/walbourn/directx-sdk-samples/tree/master/HDRToneMappingCS11)
- [Reverse engineering the rendering of The Witcher 3, part 2 - eye adaptation](https://astralcode.blogspot.com/2017/10/reverse-engineering-rendering-of.html)
- <https://github.com/przemyslawzaworski/Unity3D-CG-programming/tree/master/HDR>
