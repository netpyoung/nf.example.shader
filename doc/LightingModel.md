# Lighitng Model

- <https://www.jordanstevenstechart.com/lighting-models>
- 년도를 보면서 발전상황과 왜 쓰는지 왜 안쓰는지 확인필요.

## 비 물리기반

### Lambert - 람버트

- Johann Heinrich Lambert
- 1760 - Photometria

``` hlsl
half NdotL = max(0.0, dot(N, L));
half diffuse = NdotL;
```

## Phong - 퐁

- 1973 - Bui Tuong Phong

``` hlsl
half3 R = reflect(-L, N);
half RdotV = max(0.0f, dot(R, V));
half specular = pow(RdotV, _SpecularGloss) * _SpecularPower;
```

## Blinn Phong - 블린 퐁

- 1977 - Jim Blinn

``` hlsl
half3 H = normalize(V + L); 
half NdotL = max(0.0, dot(N, L));
half NdotH = max(0.0, dot(N, H));

half specular = pow(NdotH ,_SpecularGloss) * _SpecularPower;
```

## Minnaert - 미네르트

- 1954 - Marcel Minnaert

- 달표면 반사를 표현하기 위해 고안됨. moon shader라 불리기도 함

``` hlsl
half NdotL = max(0.0, dot(N, L));
half NdotV = max(0.0, dot(N, V));
half diffuse = NdotL * pow(NdotL * NdotV, _MinnaertDarkness);
```

## Half Lambert & Wrapped Lambert - 하프 람버트 & 와프드 람버트

- 2004 Half-Life2 - Valve
- [SIGGRAPH2006 - Shading In Valve's Source Engine](https://steamcdn-a.akamaihd.net/apps/valve/2006/SIGGRAPH06_Course_ShadingInValvesSourceEngine.pdf)

``` hlsl
// half lambert
half NdotL = max(0.0, dot(N, L));
half diffuse = pow(NdotL * 0.5 + 0.5, 2);

// wrapped lambert
half diffuse = pow(NdotL * wrapValue + (1.0 - wrapValue), 2);
half diffuse = max(0.0, (NdotL + _wrapped) / (1.0 - _wrapped));
```

``` hlsl
// ref: https://blog.naver.com/eryners/220144182154
// Harf Lambert사용시 명암 차이가 너무 없어져서 무게감이 없어보인다.
​Half Lambert + Pow : pow((dot(N, L) * 0.5) + 0.5, 4) 
```

## 물리기반

## Cook Torrance - 쿡토렌스

- 1982 - Robert L.Cook & Kenneth E. Torrance - A Reflectance Model For Computer Graphics
- 미세면이론
- 거친표면 specular 초점

## Ward - 알드

- 1992 - Gregory J. Ward - Measuring and modeling anisotropic reflection
- 경험적 데이터 기반, 거의 사용되지 않음.

## Oren-Nayar - 오렌네이어

- 1994 - Michael Oren & Shree K. Nayar - Generalization of Lambert’s Reflectance Model
- 거친포면 diffuse 초점

``` hlsl
half NdotL = max(0.0, dot(N, L));
half NdotV = max(0.0, dot(N, V));
half VdotL = max(0.0, dot(V, L));

half s = VdotL - NdotL * NdotV;
half t = lerp(1.0, max(NdotL, NdotV), step(0.0, s));

half3 A = 1.0 + _OrenNayarAlbedo * (_OrenNayarAlbedo / (_OrenNayarSigma + 0.13) + 0.5 / (_OrenNayarSigma + 0.33));
half3 B = 0.45 * _OrenNayarSigma / (_OrenNayarSigma + 0.09);

half3 diffuse = _OrenNayarAlbedo * max(0.0, NdotL) * (A + B * s / t) / 3.14159265;
```

## Modified Phong - 모디파이드 퐁

- Lafortune and Willems (1994)

``` hlsl
half norm = (shininess + 2.0) / (2.0 * PI);

half3 R = reflect(-L, N);
half3 VdotR = max(0.0, dot(V, R));

half3 specular = norm * pow(VdotR, shininess);
```

## Ashikhmin Shirley - 어크먼 셜리

- 2000 - Michael Ashikhmin & Peter Shirley - An Anisotropic Phong BRDF Model
- 퐁 스펙큘러

## Fakey Oren-Nayar -  최적화 오렌네이어

- 2011 - [pope - Rendering Tech of Space Marine](https://www.slideshare.net/blindrenderer/rendering-tech-of-space-marinekgc-2011)
  - <https://kblog.popekim.com/2011/11/blog-post_16.html>

``` hlsl
half OrenNayar_Fakey(half3 N, half3 L, half3 V, half roughness)
{
    half LdotN = dot(L, N);
    half VdotN = dot(V, N);
	
    half result = saturate(LdotN);
    half soft_rim = saturate(1 - VdotN / 2);
	
    half fakey = pow(1 - result * soft_rim, 2);
    half fakey_magic = 0.62;
    fakey = fakey_magic - fakey * fakey_magic;
    return lerp(result, fakey, roughness);
}
```


## Disney - 디즈니

- SIGGRAPH 2012 - Brent Burley - Physically Based Shading at Disney
- 여러 파라미터
