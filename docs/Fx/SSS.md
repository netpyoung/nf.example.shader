# SSS

SSS(Sub-Surface Scattering) (피하산란)

- BSSRDF(Bidirectional surface-scattering reflectance distribution function)
  - 입사한 지점과 반사되는 지점이 다름.
  - 실시간으로 계산하기에는 부하가 큼
- 여러 기법들
  - Texture-Space Diffusion
  - Scren-Space SSS
  - Pre-Integrated Skin Shading
  - other Fake/Fast/Approximated SSS

## TSD / Texture-Space Diffusion

## SSSSS / Scren-Space Sub-Surface Scattering

## PISS / Pre-Integrated Skin Shading

- LookUpTexture 이용

- fwidth : abs(ddx(x)) + abs(ddy(x))
- DirectX는 ddx_fine/ddy_fine함수도 있음.

``` hlsl
half diffuse = LdotN;
half curvature = saturate(length(fwidth(N)) / length(fwidth(positionWS)) * curvatureScale);

half2 pissUV;
pissUV.x = diffuse;
pissUV.y = curvature;

half3 pissTex = SAMPLE_TEXTURE2D(_PissTex, sampler_PissTex, pissUV).rgb;
```

## LocalThickness

``` hlsl
// local thickness
half  localTicknessTex = SAMPLE_TEXTURE2D(_LocalThicknessTex, sampler_LocalThicknessTex, uv).r;
half3 H                = normalize(L + N * _Distortion);
half  VdotH            = pow(saturate(dot(V, -H)), _Power) * _Scale;
half  backLight        = _Attenuation * (VdotH + _Ambient) * localTicknessTex;
```

## other Fake/Fast/Approximated SSS

``` hlsl
half  halfLambert = NdotL * 0.5 + 0.5;
half3 fakeSSS     = (1 - halfLambert) * _SSSColor;
half3 color       = halfLambert + fakeSSS;
```

``` hlsl
half  rim     = 1 - NdotL;
// 역광일때만 하려면 VdotL처리
// rim *= VdotL;
half3 fakeSSS = pow(rim, _SSSPower) * _SSSMultiplier * _SSSColor;
half3 color   = lambert * fakeSSS;
```

``` hlsl
half  rim     = 1 - NdotL;
half3 fakeSSS = SAMPLE_TEXTURE2D(_SSS_RampTex, sampler_SSS_RampTex, half2(rim, 0)).rgb;
```

``` hlsl
half2 brdfUV;
brdfUV.x = dot(N, L);
brdfUV.y = dot(N, H);

half3 brdfTex = SAMPLE_TEXTURE2D(_BrdfTex, sampler_BrdfTex, brdfUV * 0.5 + 0.5).rgb;
```

``` hlsl
half LdotN = dot(L, N);
half LdotV = dot(L, V);

half2 rampUV;
rampUV.x = LdotN * 0.3 + 0.5;
rampUV.y = LdotV * 0.8;
half3 rampTex = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, rampUV).rgb;
```

아니면 Albedo맵 / Normal맵 자체에 Blur(rgb에 가중치를 주어서)를 적용한다.

## Ref

- [Cheap realisticskinshading kor ](https://www.slideshare.net/leemwymw/cheap-realisticskinshading-kor)
- [SIGGRAPH2010 - Uncharted 2: Character Lighting and Shading](https://advances.realtimerendering.com/s2010/index.html)
- [GDC2011 - Iterating Realistic Human Rendering: Boxers in FIGHT NIGHT CHAMPION](https://www.gdcvault.com/browse/gdc-11/play/1014661)
- <https://zhuanlan.zhihu.com/p/97892884>
- <https://blog.naver.com/checkjei/60167971452>
- <https://therealmjp.github.io/posts/sss-intro/>
- <https://mgun.tistory.com/1600>
- NVIDIA
  - <https://developer.download.nvidia.com/books/HTML/gpugems/gpugems_ch16.html>
  - <https://developer.nvidia.com/gpugems/gpugems3/part-iii-rendering/chapter-14-advanced-techniques-realistic-real-time-skin>
  - <https://github.com/NVIDIAGameWorks/FaceWorks>
- 기법별
  - using Half lambert
    - [SSS 쉐이더 만들었어요 뿌우](http://chulin28ho.egloos.com/5591833)
  - Pre-Integrated Skin Shading
    - GPU Pro 2 - Pre-Integrated Skin Shading
  - LocalThickness
    - GPU Pro 2 - Real-Time Approximation of Light Transport in Translucent Homogenous Media
    - [GDC 2011 – Approximating Translucency for a Fast, Cheap and Convincing Subsurface Scattering Look](https://colinbarrebrisebois.com/2011/03/07/gdc-2011-approximating-translucency-for-a-fast-cheap-and-convincing-subsurface-scattering-look/)
    - Fast Subsurface Scattering in Unity([1](https://www.alanzucconi.com/2017/08/30/fast-subsurface-scattering-1/), [2](https://www.alanzucconi.com/2017/08/30/fast-subsurface-scattering-2/))
    - 실시간 SSS 셰이더 구현하는 세가지 방법([1](https://blog.naver.com/mnpshino/221442188568), [2](https://blog.naver.com/mnpshino/221442196618), [3](https://blog.naver.com/mnpshino/221442210257))
    - [SSS Shader for Unity](https://chulin28ho.tistory.com/515)
  - Normal blur
    - [[ 기고 ] Normal Blur Sub-Surface Scattering](https://lifeisforu.tistory.com/517)
    - NOC2012 - SubSurfaceScattering + UDK Custom Shader 권오찬
  - [SIGGRAPH2011 - Penner pre-integrated skin rendering](https://www.slideshare.net/leegoonz/penner-preintegrated-skin-rendering-siggraph-2011-advances-in-realtime-rendering-course)
  - BRDF
    - [Brdf기반 사전정의 스킨 셰이더](https://www.slideshare.net/jalnaga/brdf)
