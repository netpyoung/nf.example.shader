# SSS

- SSS(Sub-Surface Scattering) (피하산란)

- 실시간 SSS 셰이더 구현하는 세가지 방법 (1) https://blog.naver.com/mnpshino/221442188568
- 실시간 SSS 셰이더 구현하는 세가지 방법 (2) https://blog.naver.com/mnpshino/221442196618
- 실시간 SSS 셰이더 구현하는 세가지 방법 (3) https://blog.naver.com/mnpshino/221442210257
// [SSS 쉐이더 만들었어요 뿌우](http://chulin28ho.egloos.com/5591833)
[Brdf기반 사전정의 스킨 셰이더](https://www.slideshare.net/jalnaga/brdf)

- https://zhuanlan.zhihu.com/p/97892884
- https://chulin28ho.tistory.com/515
- https://blog.naver.com/checkjei/60167971452
- https://therealmjp.github.io/posts/sss-intro/
- https://developer.download.nvidia.com/books/HTML/gpugems/gpugems_ch16.html
- https://lifeisforu.tistory.com/517
- https://mgun.tistory.com/1600

- Fake/Fast/Approximated SSS
- thickness map
- BRDF

## Fake/Fast/Approximated SSS

- halfLambert에 색깔입히는 방법
- rim에 색깔 입히는 방법
- rim을 UV로 Ramp Texture이용하는 방법
- brdf LUT Texture 이용하는 방법

``` hlsl
half halfLambert = NdotL * 0.5 + 0.5;
half3 fakeSSS = halfLambert * _SSSColor;
half3 color = halfLambert + fakeSSS;
```

``` hlsl
half rim = 1 - NdotL;
half3 fakeSSS = pow(rim, _SSSPower) * _SSSMultiplier * _SSSColor;
half3 color = lambert * fakeSSS;
```

``` hlsl
half rim = 1 - NdotL;
half3 fakeSSS = SAMPLE_TEXTURE2D(_SSS_RampTex, sampler_SSS_RampTex, half2(rim, 0)).rgb;
```

``` hlsl
half2 brdfUV;
brdfUV.x = dot(N, L);
brdfUV.y = dot(N, H);
half3 light = tex2D(_BRDF_LUT_Tex, sampler_BRDF_LUT_Tex, brdfUV * 0.5 + 0.5).rgb;
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



  
  BSSRDF( Bidirectional Scattering-Surface Reflectance Distribution Function ) 예 이미지
  피부중심
 - 여전히 무거움  Texture-Space SSS 나 Scren-Space SSS( S5 ), Pre-Integrated SSS
 - Fake SSS - approximated SSS 

초간단  - 16.2 Simple Scattering Approximations

LUT 생성
float diffuse = max(0, dot(L, N));
float wrap_diffuse = max(0, (dot(L, N) + wrap) / (1 + wrap));

float4 GenerateSkinLUT(float2 P : POSITION) : COLOR
{
  float wrap = 0.2;
  float scatterWidth = 0.3;
  float4 scatterColor = float4(0.15, 0.0, 0.0, 1.0);
  float shininess = 40.0;

  float NdotL = P.x * 2 - 1;  // remap from [0, 1] to [-1, 1]

  
   float NdotH = P.y * 2 - 1;

  float NdotL_wrap = (NdotL + wrap) / (1 + wrap); // wrap lighting
  
   float diffuse = max(NdotL_wrap, 0.0);

  // add color tint at transition from light to dark
  
   float scatter = smoothstep(0.0, scatterWidth, NdotL_wrap) *
                    smoothstep(scatterWidth * 2.0, scatterWidth,
                               NdotL_wrap);

  float specular = pow(NdotH, shininess);
  if (NdotL_wrap <= 0) specular = 0;
  float4 C;
  C.rgb = diffuse + scatter * scatterColor;
  C.a = specular;
  return C;
}


깊이맵 반투명 흡수 - 16.3 Simulating Absorption Using Depth Maps

