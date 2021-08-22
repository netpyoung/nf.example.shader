# ToneMapping

- 컴퓨터 모니터와 같은 LDR 매체에서 볼 수 있지만 HDR 이미지의 선명도와 톤 범위를 갖는 결과 이미지를 생성

|                                     | nits   |
|-------------------------------------|--------|
| eye                                 | 40,000 |
| LDR/SDR(Low/Standard Dynamic Range) | 100    |
| HDR(High Dynamic Range)             | 1,000  |

- Tone-mapping -> 디스플레이에 출력가능한 값
- 평균 Luminance
- Luminance 중심으로 0~1 : Tone Mapping
- RGB -> CIE XYZ -> CIE Yxy -> y : Luminance

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

ICtCp
YCgCo

ACES - Academy Color Encoding System 
https://en.wikipedia.org/wiki/Academy_Color_Encoding_System
https://github.com/ampas/aces-dev
https://www.slideshare.net/hpduiker/acescg-a-common-color-encoding-for-visual-effects-applications

CIE XYZ

X -
Y 휘도
Z 청색 자극

- ITU1990

``` hlsl
const static half3x3 MAT_RGB_TO_XYZ = {
    0.4124, 0.3576, 0.1805,
    0.2126, 0.7152, 0.0722,
    0.0193, 0.1192, 0.9505
};

const static half3x3 MAT_XYZ_TO_RGB = {
    +3.2405, -1.5371, -0.4985,
    -0.9693, +1.8760, +0.0416,
    +0.0556, -0.2040, +1.0572
};
```

``` hlsl
// ======================================
/// XYZ => Yxy
float SUM_XYZ = dot(float3(1.0, 1.0, 1.0), XYZ);
Yxy.r  = XYZ.g;
Yxy.gb = XYZ.rg / SUM_XYZ;

// ======================================
/// Yxy => XYZ
XYZ.r = Yxy.r * Yxy.g / Yxy. b;
XYZ.g = Yxy.r;
XYZ.b = Yxy.r * (1 - Yxy.g - Yxy.b) / Yxy.b;
```

CIE Yxy
CIE Lab


XYZ
Yxy

## Simple

### GrayScale / Monochrome

``` hlsl
// YUV로 변환후, 밝기만 취하기.
const static half3x3 MAT_RGB_TO_YUV = {
  +0.299, +0.587, +0.114, // 밝기
  -0.147, -0.289, +0.436,
  +0.615, -0.515, -0.100
};

const static half3x3 MAT_YUV_TO_RGB = {
  +1.0, +0.000, +1.140,
  +1.0, -0.396, -0.581,
  +1.0, +2.029, +0.000
};

half YUV_y = mul(MAT_RGB_TO_YUV[0], color.rgb);
```

### Sepia

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

const static half3x3 MAT_RGB_TO_YUV = {
  +0.299, +0.587, +0.114, // 밝기
  -0.147, -0.289, +0.436,
  +0.615, -0.515, -0.100
};

const static half3x3 MAT_YUV_TO_RGB = {
  +1.0, +0.000, +1.140,
  +1.0, -0.396, -0.581,
  +1.0, +2.029, +0.000
};
```

## ToneMappings

- Reinhard

``` hlsl
float3 Reinhard(float3 v)
{
    return v / (1.0f + v);
}

float3 Reinhard_extended(float3 v, float max_white)
{
    float3 numerator = v * (1.0f + (v / float3(max_white * max_white)));
    return numerator / (1.0f + v);
}

```

- Flimic - Jim Hejl and Richard Burgess-Dawson
  - color_Linear => flmic => result_Gamma

``` hlsl
half3 TonemapFilmic(half3 color_Linear)
{
    // optimized formula by Jim Hejl and Richard Burgess-Dawson
    half3 X = max(color_Linear - 0.004, 0.0);
    half3 result_Gamma = (X * (6.2 * X + 0.5)) / (X * (6.2 * X + 1.7) + 0.06);
    return pow(result_Gamma, 2.2); // convert Linear Color
}
```

- Uncharted2 - John Hable

| param         |                  |
|---------------|------------------|
| Exposure_Bias |                  |
| A             | Soulder Strength |
| B             | Linear Strength  |
| C             | Linear Angle     |
| D             | Toe Strength     |
| E             | Toe Numerator    |
| F             | Toe Denominator  |
| LinearWhite   |                  |

``` hlsl
float3 Uncharted2_tonemap_partial(float3 x)
{
    const float A = 0.15f;
    const float B = 0.50f;
    const float C = 0.10f;
    const float D = 0.20f;
    const float E = 0.02f;
    const float F = 0.30f;
    return ((x * (A * x + C * B) + D * E) / (x * (A * x + B) + D * F)) - (E / F);
}

float3 Uncharted2_filmic(float3 v)
{
    float exposure_bias = 2.0f;
    float3 curr = Uncharted2_tonemap_partial(v * exposure_bias);

    float3 W = 11.2f;
    float3 white_scale = 1.0 / Uncharted2_tonemap_partial(W);
    return curr * white_scale;
}
```

- Flimic_Hejl2015

``` hlsl
half3 TonemapFilmic_Hejl2015(half3 hdr, half whitePoint)
{
    half4 vh = half4(hdr, whitePoint);
    half4 va = (1.425 * vh) + 0.05;
    half4 vf = ((vh * va + 0.004) / ((vh * (va + 0.55) + 0.0491))) - 0.0821;
    return vf.rgb / vf.aaa;
}
```

- ACES: based on ‘ACES Filmic Tone Mapping Cuve‘ by Narkowicz in 2015. - unreal 4.8

``` hlsl
// sRGB => XYZ => D65_2_D60 => AP1 => RRT_SAT
static const float3x3 ACESInputMat =
{
    {0.59719, 0.35458, 0.04823},
    {0.07600, 0.90834, 0.01566},
    {0.02840, 0.13383, 0.83777}
};

// ODT_SAT => XYZ => D60_2_D65 => sRGB
static const float3x3 ACESOutputMat =
{
    { 1.60475, -0.53108, -0.07367},
    {-0.10208,  1.10813, -0.00605},
    {-0.00327, -0.07276,  1.07602}
};

float3 RRTAndODTFit(float3 v)
{
    float3 a = v * (v + 0.0245786f) - 0.000090537f;
    float3 b = v * (0.983729f * v + 0.4329510f) + 0.238081f;
    return a / b;
}

float3 ACES_Fitted(float3 color)
{
    color = mul(ACESInputMat, color);

    // Apply RRT and ODT
    color = RRTAndODTFit(color);

    color = mul(ACESOutputMat, color);

    // Clamp to [0, 1]
    color = saturate(color);

    return color;
}
```

- Uchimura: from ‘HDR theory and practice‘ by Hajime Uchimura in 2017. Used in ‘Gran Turismo‘.

- Unreal: Used in Unreal Engine 3 up to 4.14. Adapted to be close to ACES, with similar range.

``` hlsl
float3 Unreal3(float3 color_Linear)
{
    float3 result_Gamma = color_Linear / (color_Linear + 0.155) * 1.019;
    return pow(result_Gamma, 2.2); // convert Linear Color
}
```

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
- <https://github.com/tizian/tonemapper>
- <https://64.github.io/tonemapping/>
- <https://www.slideshare.net/nikuque/hdr-theory-and-practicce-jp>
- Color Control : <https://www.slideshare.net/cagetu/928501785227148871>
- [SIGGRAPH2016 - Technical Art of Uncharted 4](http://advances.realtimerendering.com/other/2016/naughty_dog/index.html)
- [GDC2017 - High Dynamic Range Color Grading and Display in Frostbite](https://www.youtube.com/watch?v=7z_EIjNG0pQ)
- https://mynameismjp.wordpress.com/2010/04/30/a-closer-look-at-tone-mapping/
- http://renderwonk.com/publications/s2010-color-course/
- [shadertoy -  Tone mapping](https://www.shadertoy.com/view/lslGzl)

GDC2004 - Advanced Depth of Field
- [GDC2009 - Star Ocean 4 - Flexible Shader Managment and Post-processing](https://www.slideshare.net/DAMSIGNUP/so4-flexible-shadermanagmentandpostprocessing)
