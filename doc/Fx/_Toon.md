# Toon

- ceil / Ramp Texture / smoothstep

``` hlsl
// ===== 계단 음영 표시 - ver. ceil() ====
// [0, 1]범위를 _ToonStep(int)을 곱해서 [0, _ToonStep]범위로 변경.
// ceil함수를 이용하여 올림(디테일 제거 효과).
// 다시 _ToonStep(int)으로 나눔으로써 [0, 1]범위로 변경.
half toonDiffuse = halfLambert;
toonDiffuse = ceil(toonDiffuse * _ToonStep) / _ToonStep;

// ===== 계단 음영 표시 - ver. Ramp Texture ====
// 아니면 Ramp Texture 이용
half3 toonColor = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, half2(halfLambert, 0)).rgb;

// ===== 림라이트 ======================
// smoothstep으로 경계를 부드럽게 혼합.
half rim = 1 - NdotV;
half rimIntensity = smoothstep(0.715, 0.717, rim);

// 아니면, 빛방향으로 림
half rimIntensity = rim * pow(NdotL, 0.1);

// ===== 스펙큘러 ======================
// smoothstep으로 경계를 부드럽게 혼합.
half toonSpecular = smoothstep(0.005, 0.01, blinnphongSpecular);
```

## 아웃라인

- 버텍스 확장
  - 단순 확장
  - 버텍스 칼라이용 세부 조절
- 포스트이펙트

## 기타 예제

- SSS 텍스쳐

``` hlsl
half3 sssColor = mainTex * sssTex;
half3 afterSssColor = lerp(sssColor, mainTex, diffuse);
```

- maskTex

| 채널 | 마스크        |
| ---- | ------------- |
| r    | 반사영역      |
| g    | 어두어짐      |
| b    | 스펙큘러 세기 |
| a    | 내부 선       |

- vertex's color

| 채널 | 마스크                                  |
| ---- | --------------------------------------- |
| r    | 어두워짐                                |
| g    | 카메라와의 거리                         |
| b    | 카메라의 zoffset. 헤어에서 storoke 조절 |
| a    | 윤곽두께                                |

## Ref

- <https://alexanderameye.github.io/simple-toon.html>
- <https://roystan.net/articles/toon-shader.html>
  - <https://github.com/IronWarrior/UnityToonShader>
- [The Art Direction of Street Fighter V: The Role of Art in Fighting Games](https://www.youtube.com/watch?v=EDlbJdmo7KE)
  - <https://www.gdcvault.com/play/1024506/Art-Direction-of-Street-Fighter>
- [[마비노기] 마비노기 카툰렌더링 제작과정 영상 [Mabinogi] Cartoon rendering Production Process Video](https://www.youtube.com/watch?v=lYV_-x2aFX0)
- [SIGGRAPH2006 - Shading In Valve's Source Engine](https://steamcdn-a.akamaihd.net/apps/valve/2006/SIGGRAPH06_Course_ShadingInValvesSourceEngine.pdf)
  - [NPAR07_IllustrativeRenderingInTeamFortress2](https://steamcdn-a.akamaihd.net/apps/valve/2007/NPAR07_IllustrativeRenderingInTeamFortress2.pdf)
  - [Team Fortress 2 Shader for RenderMan RSL](https://vimeo.com/25953235)
