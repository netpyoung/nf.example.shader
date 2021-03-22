

 SubSurfaceScattering (피하산란)
실시간 SSS 셰이더 구현하는 세가지 방법 (1) https://blog.naver.com/mnpshino/221442188568
실시간 SSS 셰이더 구현하는 세가지 방법 (2) https://blog.naver.com/mnpshino/221442196618
실시간 SSS 셰이더 구현하는 세가지 방법 (3) https://blog.naver.com/mnpshino/221442210257



## Fake SSS

``` hlsl
half halfLambert = NdotL * 0.5 + 0.5;
half3 fakeSSS = halfLambert * _SSSColor;
half3 color = halfLambert + fakeSSS;
```

// [SSS 쉐이더 만들었어요 뿌우](http://chulin28ho.egloos.com/5591833)
``` hlsl
half lambert = NdotL;
half invLambert = 1 - lambert;
half3 fakeSSS = pow(invLambert, _SSSPower) * _SSSMultiplier * _SSSColor;
half3 color = lambert * fakeSSS;

```

// [SSS Shader for Unity](https://chulin28ho.tistory.com/515)

thickness map 
https://blender.stackexchange.com/questions/100724/how-to-bake-a-fake-sss-map-thickness-map
https://colinbarrebrisebois.com/2011/04/04/approximating-translucency-part-ii-addendum-to-gdc-2011-talk-gpu-pro-2-article/

## gpggem 16



[Chapter 16. Real-Time Approximations to Subsurface Scattering](https://developer.download.nvidia.com/books/HTML/gpugems/gpugems_ch16.html)
16.2 Simple Scattering Approximations
float diffuse = max(0, dot(L, N));
float wrap_diffuse = max(0, (dot(L, N) + wrap) / (1 + wrap));

wrap_diffuse를 이용 스킨LUT 텍스쳐를 생성하고, LUT텍스쳐를 이용 light값을 얻어온다.

16.3 Simulating Absorption Using Depth Maps
깊이맵을 이용.

## 
BRDF Texture
원본 R값 블러로 새로운 노멀맵.
원본NormalMap, 새로운 NromalMap의 BRDF의 R채널 기준 Lerp
[Brdf기반 사전정의 스킨 셰이더](https://www.slideshare.net/jalnaga/brdf)

## 

SubSurface Scattering
  SubSurface Scattering
  Mid-Tone RedBias
  Transmission
Oren-Nayar
  Custom HalfLambert
  Silhouette

- 
- BRDF 텍스쳐를 이용(Fake SSS)


SSS 
   포토샵을 이용해서 미리 Blur 가 적용된 텍스쳐를 생성한다.
 Normal 텍스쳐에 Blur 를 적용한다.
 산란을 위한 레이어는 2단계로 제한한다.
 RGB채널을 각각 연산하여 마지막에 합친다

Mid-Tone RedBias
  
 HalfLambert와 Lambertian 사이의 차이를 추출해서 이용.
 Diffuse 채널에 추가.

Transmission
 귀, 손가락, 코끝은 Texture로, 실루엣은 Fresnel로 영역을 지정한다.
 Emissive 채널에 합성한다.
 카메라 벡터와 라이트 벡터를 이용해서 역광이 아닌 상황을 걸러낸다.

Silhouette
 Fresnel 함수를 이용해서 외곽선 검출
 Silhouette 칼라는 디퓨즈 칼라를 Multiply로 추가.
 카메라벡터와 라이트벡터의 Dot Product를 이용해서 역광을 검출
 역광 검출을 이용해서 외곽 Transmission 효과를 추가.


## ScreenSpace SSS ??



## ref

SubSurfaceScattering + UDK Custom Shader 권오찬

https://blog.naver.com/mnpshino/221442188568