# PostProcess

- Compute 셰이더가 좀 더 빠르지만, 여기선 일단 픽셀 셰이더로 구현하는 걸로.

## 크로스 필터 HDR

- 색상값이 높은 부분을 추출하여 여러 방향으로 합성
  - 부하가 크니 추출 버퍼를 작은 사이즈로

## 영역 총합 테이블 (summed area table)

- 1984 - Frank
- GDC2003 - Simon

## 모자이크

- 축소버퍼나 floor이용

## 필터

### 색공간

https://en.wikipedia.org/wiki/YUV - TODO 이미지
| YUV |             |
|-----|-------------|
| Y   | 밝기        |
| U   | 파랑 - 밝기 |
| V   | 빨강 - 밝기 |
YCbCr - digital
YPbPr - analog

https://en.wikipedia.org/wiki/YIQ - TODO 이미지
YUV 33도 회전
- NTSC(National Television System Committee)방식 -한국 미국 컬러텔레비전
| YIQ |             |
|-----|-------------|
| Y   | 밝기        |
| I   | 파랑 - 밝기 |
| Q   | 빨강 - 밝기 |

The CMY color model is a subtractive color model 
 
| CMY |         |
|-----|---------|
| C   | Cyan    |
| M   | Magenta |
| Y   | Yellow  |

| CMYK |            |
|------|------------|
| C    | Cyan       |
| M    | Magenta    |
| Y    | Yellow     |
| K    | Key(black) |

HSV
H 색상(Hue)
S 채도(Saturation)
V 명도(value)

### GrayScale

https://danielilett.com/2019-05-01-tut1-1-smo-greyscale/

- grayscale : https://en.wikipedia.org/wiki/Grayscale
https://blog.ggaman.com/965

``` hlsl
YPrPb
Y = 0.299  * R + 0.587  * G + 0.114  * B
Y = 0.3  * R + 0.6  * G + 0.11  * B

YCrCb
Y = 0.2126 * R + 0.7152 * G + 0.0722 * B
```

http://www.songho.ca/dsp/luminance/luminance.html

fast approximation
integer domain은 float보다 빠르다. shader는 float범위([0, 1])이므로 별 유용성은 없지만. 다른 곳에서는 유용할 수 도 있을듯

2/8 = 0.25
5/8 = 0.625
1/8 = 0.125


Luminance = (2 * Red + 5 * Green + 1 * Blue) / 8 
Y = (R << 1)
Y += (G << 2 + G)
Y += B
Y >>= 8
 
### Sepia Tone Filter

?? http://www.aforgenet.com/framework/docs/html/10a0f824-445b-dcae-02ef-349d4057da45.htm

``` hlsl
half3x3 sepiaVals = half3x3
(
    0.393, 0.349, 0.272,    // Red
    0.769, 0.686, 0.534,    // Green
    0.189, 0.168, 0.131     // Blue
);

half3 sepiaResult = mul(tex.rgb, sepiaVals);
```

    transform to YIQ color space;
    modify it;
    transform back to RGB.


### Midium filter

- 주변 여러 픽셀 중간값

## 잔상

- 이전버퍼 현재버퍼 합성
  - ex) 빛이 강한 부분만 잔상남기기

## 모션블러

- 이전 좌표 현재좌표 합성

## 윤곽 추출 / Edge Detection

- 윤곽추출
  - 색성분
  - ID 엣지
  - 깊이 엣지
  - 모델 확대
