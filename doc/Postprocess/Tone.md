# Tone

## Color Space

| RGB |       |
|-----|-------|
| R   | Red   |
| G   | Green |
| B   | Blue  |

| CMYK |            |
|------|------------|
| C    | Cyan       |
| M    | Magenta    |
| Y    | Yellow     |
| K    | Key(black) |

| HSV |                  |
|-----|------------------|
| H   | 색상(Hue)        |
| S   | 채도(Saturation) |
| V   | 명도(value)      |

| YUV |             |
|-----|-------------|
| Y   | 밝기        |
| U   | 파랑 - 밝기 |
| V   | 빨강 - 밝기 |

| YUV 종류 |                                                                                        |
|----------|----------------------------------------------------------------------------------------|
| YCbCr    | digital                                                                                |
| YPbPr    | analog                                                                                 |
| YIQ      | YUV 33도 회전, NTSC(National Television System Committee)방식 -한국, 미국 컬러텔레비전 |

ACES - Academy Color Encoding System 
https://en.wikipedia.org/wiki/Academy_Color_Encoding_System
https://github.com/ampas/aces-dev
https://www.slideshare.net/hpduiker/acescg-a-common-color-encoding-for-visual-effects-applications

## GrayScale / Monochrome

``` hlsl
// YUV로 변환후, 밝기만 취하기.
half3x3 MAT_RGB_TO_YUV = {
  +0.299, +0.587, +0.114, // 밝기
  -0.147, -0.289, +0.436,
  +0.615, -0.515, -0.100
};

half3x3 MAT_YUV_TO_RGB = {
  +1.0, +0.000, +1.140,
  +1.0, -0.396, -0.581,
  +1.0, +2.029, +0.000
};

half YUV_y = mul(MAT_RGB_TO_YUV[0], color.rgb);
```

## Sepia Tone

- MS문서에 나온 SepiaMatrix 이용.
- YIQ나 YUV 이용.

``` hlsl
half3x3 MAT_TO_SEPIA = {
    0.393, 0.769, 0.189,   // tRed
    0.349, 0.686, 0.168,   // tGreen
    0.272, 0.534, 0.131    // tBlue
};

half3 sepiaResult = mul(MAT_TO_SEPIA, color.rgb);
```

``` hlsl
// ref: http://www.aforgenet.com/framework/docs/html/10a0f824-445b-dcae-02ef-349d4057da45.htm
// I = 51
// Q = 0

half3x3 MAT_RGB_TO_YIQ = {
    +0.299, +0.587, +0.114,
    +0.596, -0.274, -0.322,
    +0.212, -0.523, +0.311
};

half3x3 MAT_YIQ_TO_RGB = {
    +1.0, +0.956, +0.621,
    +1.0, -0.272, -0.647,
    +1.0, -1.105, +1.702
};
```

``` hlsl
// Cb : -0.2
// Cr : 0.1

half3x3 MAT_RGB_TO_YUV = {
  +0.299, +0.587, +0.114, // 밝기
  -0.147, -0.289, +0.436,
  +0.615, -0.515, -0.100
};

half3x3 MAT_YUV_TO_RGB = {
  +1.0, +0.000, +1.140,
  +1.0, -0.396, -0.581,
  +1.0, +2.029, +0.000
};
```

## 

Linear
Reinhard
Flimic - Jim Hejl and Richard Burgess-Dawson
 - color_Linear => flmic => color_Gamma
Uncharted2 - John Hable
| param       |                          |
|-------------|--------------------------|
| A           | Soulder Strength         |
| B           | Linear Strength          |
| C           | Linear Angle             |
| D           | Toe Strength             |
| E           | Toe Numerator            |
| F           | Toe Denominator          |
| LinearWhite | Linear White Point Value |

Flimic_Hejl2015

``` hlsl
half3 TonemapFilmic_Hejl2015(half3 hdr, half whitePoint)
{
    half4 vh = half4(hdr, whitePoint);
    half4 va = (1.425 * vh) + 0.05;
    half4 vf = ((vh * va + 0.004) / ((vh * (va + 0.55) + 0.0491))) - 0.0821;
    return vf.rgb / vf.aaa;
}
```

ACES: based on ‘ACES Filmic Tone Mapping Cuve‘ by Narkowicz in 2015.
Uchimura: from ‘HDR theory and practice‘ by Hajime Uchimura in 2017. Used in ‘Gran Turismo‘.
Unreal: Used in Unreal Engine 3 up to 4.14. Adapted to be close to ACES, with similar range.




## Ref

- <https://danielilett.com/2019-05-01-tut1-1-smo-greyscale/>
- <https://en.wikipedia.org/wiki/Grayscale>
- <https://blog.ggaman.com/965>
- <https://docs.microsoft.com/en-us/archive/msdn-magazine/2005/january/net-matters-sepia-tone-stringlogicalcomparer-and-more>
- <https://www.gdcvault.com/play/1012351/Uncharted-2-HDR>
  - <https://www.slideshare.net/naughty_dog/lighting-shading-by-john-hable>
  - <http://filmicworlds.com/blog/filmic-tonemapping-operators/>
  - <https://github.com/dmnsgn/glsl-tone-map>
- <https://twitter.com/jimhejl/status/633777619998130176>
- https://github.com/tizian/tonemapper