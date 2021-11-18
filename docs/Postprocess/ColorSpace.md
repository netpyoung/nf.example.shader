# Color Space

- RGB
- HSL (for hue, saturation, lightness) and HSV (for hue, saturation, value; also known as HSB, for hue, saturation, brightness) 
- HCL (Hue-Chroma-Luminance)
- YUV
- ..

| RGB |       |
| --- | ----- |
| R   | Red   |
| G   | Green |
| B   | Blue  |

| CMYK |            |
| ---- | ---------- |
| C    | Cyan       |
| M    | Magenta    |
| Y    | Yellow     |
| K    | Key(black) |

| HSV |                                      |
| --- | ------------------------------------ |
| H   | 색상(Hue)                            |
| S   | 채도(Saturation)                     |
| V   | 명도(Value / Lightness / Brightness) |

| YUV |             |
| --- | ----------- |
| Y   | 밝기        |
| U   | 파랑 - 밝기 |
| V   | 빨강 - 밝기 |

| YUV 종류 |                                                                                        |
| -------- | -------------------------------------------------------------------------------------- |
| YCbCr    | digital                                                                                |
| YPbPr    | analog                                                                                 |
| YIQ      | YUV 33도 회전, NTSC(National Television System Committee)방식 -한국, 미국 컬러텔레비전 |

ICtCp : ICtCp has near constant luminance, which improves chroma subsampling versus YCBCR
YCgCo : 색평면 사이에 상관성이 매우 낮음

ACES - Academy Color Encoding System 
https://en.wikipedia.org/wiki/Academy_Color_Encoding_System
https://github.com/ampas/aces-dev
https://www.slideshare.net/hpduiker/acescg-a-common-color-encoding-for-visual-effects-applications

CIE RGB
CIE XYZ
CIE Lab

| XYZ |           |
| --- | --------- |
| X   | ??        |
| Y   | 휘도      |
| Z   | 청색 자극 |

- ITU1990

## Simple

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

``` hlsl
// https://www.ronja-tutorials.com/post/041-hsv-colorspace/

float3 hue2rgb(float hue)
{
    hue = frac(hue); //only use fractional part
    float r = abs(hue * 6 - 3) - 1; //red
    float g = 2 - abs(hue * 6 - 2); //green
    float b = 2 - abs(hue * 6 - 4); //blue
    float3 rgb = float3(r,g,b); //combine components
    rgb = saturate(rgb); //clamp between 0 and 1
    return rgb;
}

float3 hsv2rgb(float3 hsv)
{
    float3 rgb = hue2rgb(hsv.x); //apply hue
    rgb = lerp(1, rgb, hsv.y); //apply saturation
    rgb = rgb * hsv.z; //apply value
    return rgb;
}

float3 rgb2hsv(float3 rgb)
{
    float maxComponent = max(rgb.r, max(rgb.g, rgb.b));
    float minComponent = min(rgb.r, min(rgb.g, rgb.b));
    float diff = maxComponent - minComponent;
    float hue = 0;
    if(maxComponent == rgb.r)
    {
        hue = 0+(rgb.g-rgb.b)/diff;
    }
    else if(maxComponent == rgb.g)
    {
        hue = 2+(rgb.b-rgb.r)/diff;
    }
    else if(maxComponent == rgb.b)
    {
        hue = 4+(rgb.r-rgb.g)/diff;
    }
    hue = frac(hue / 6);
    float saturation = diff / maxComponent;
    float value = maxComponent;
    return float3(hue, saturation, value);
}
```

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

## Ref

- <https://raphlinus.github.io/color/2021/01/18/oklab-critique.html>
- <https://bottosson.github.io/posts/oklab/>