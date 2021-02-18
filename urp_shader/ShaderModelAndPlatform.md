# 셰이더 모델과 플렛폼 관계

## Shader Model

| model | desc                                                           |
|-------|----------------------------------------------------------------|
| 2.5   | derivatives                                                    |
| 3.0   | 2.5 + interpolators10 + samplelod + fragcoord                  |
| 3.5   | 3.0 + interpolators15 + mrt4 + integers + 2darray + instancing |
| 4.0   | 3.5 + geometry                                                 |
| 5.0   | 4.0 + compute + randomwrite + tesshw + tessellation            |
| 4.5   | 3.5 + compute + randomwrite                                    |
| 4.6   | 4.0 + cubearray + tesshw + tessellation                        |

| #pragma target | 설명            |
|----------------|-----------------|
| 2.5            | 기본값 / WebGL1 |
| 3.0            | WebGL2          |
| 3.5            | es3.0  / Vulkan |
| 4.5            | es3.1           |

## 안드로이드와 그래픽 라이브러리

| Graphic Library | Android API | Android version | 코드명     |
|-----------------|-------------|-----------------|------------|
| es2.0           | 8           | 2.2.x           | Froyo      |
| es3.0           | 18          | 4.3.x           | Jelly Bean |
| es3.1           | 21          | 5.0             | Lollipop   |
| Vulkan          | 24          | 7.0             | Nougat     |

## 레퍼런스 디바이스

| 년도 | 디바이스 | 안드로이드 버전        | 지원           | android api |
|------|----------|------------------------|----------------|-------------|
| 2020 | 노트 20  | 10 → 11                | es3.1 / Vlukan | 29          |
| 2019 | 노트 10  | 9  → 10 → 11           | es3.1 / Vlukan | 28          |
| 2018 | 노트 9   | 8.1  → 9  → 10         | es3.1 / Vlukan | 27          |
| 2018 | 노트 8   | 7.1 → 8.0 → 9          | es3.1 / Vlukan | 25          |
| 2016 | 노트 7   | 6.0  // 베터리폭탄     | es3.1          | 23          |
| 2015 | 노트 5   | 5.1 → 6.0  → 7.0       | es3.1          | 22          |
| 2014 | 노트 4   | 4.4 → 5.0 → 5.1  → 6.0 | es3.0          | 19          |

## Ref

- <https://docs.unity3d.com/Manual/SL-ShaderCompileTargets.html>
- <https://developer.android.com/guide/topics/graphics/opengl?hl=ko>
- <https://source.android.com/setup/start/build-numbers?hl=ko>
- <https://developer.android.com/ndk/guides/graphics/getting-started?hl=ko>
- <https://forum.unity.com/threads/severe-banding-with-webgl-on-chrome.310326/#post-2035482>
- <https://blog.mozilla.org/futurereleases/2015/03/03/an-early-look-at-webgl-2/>

=========
_CameraDepthTexture
_CameraDepthAttachment
_CameraNormalsTexture
_CameraOpaqueTexture 불투명 채널에서 렌더링 된 후
_CameraColorTexture  반투명 채널이 렌더링 된 후

universal/Shared/Library/DeclareDepthTexture.hlsl   _CameraDepthTexture
universal/Shared/Library/DeclareNormalsTexture.hlsl _CameraNormalsTexture
universal/Shared/Library/DeclareOpaqueTexture.hlsl  _CameraOpaqueTexture

===============
모바일에서 활용할 수 있는 URP 기반 게임 개발 템플릿 프로젝트
https://www.youtube.com/watch?v=QqTeElxbTA0

dpi설정부분
http://www.unitysquare.co.kr/growwith/resource/#;
==========
Dev Weeks: A3 Still Alive - Technical Art Review
https://www.youtube.com/watch?v=ufNYLgE2WGA

water
fog
hair
footprint
==
Unity Tutorial - Emissive Lighting & Post Processing
https://www.youtube.com/watch?v=sAH0mj0tGMo

=================================

Shader 코드 디버깅
https://docs.unity3d.com/Manual/SL-DebuggingD3D11ShadersWithVS.html
https://docs.microsoft.com/en-us/visualstudio/debugger/graphics/visual-studio-graphics-diagnostics?view=vs-2019&WT.mc_id=DT-MVP-4038148

https://www.sysnet.pe.kr/Default.aspx?mode=2&sub=0&pageno=0&detail=1&wid=11693
#pragma enable_d3d11_debug_symbols

빈C++ project

``` txt
Project Property Pages
  - Platform> x64
  - Configure Properties> Debugging> Command> exe path
  - Configure Properties> Debugging> Command Arguments> -force-d3d11
```

Debugging 중에 Capture Frame

=================

https://assetstore.unity.com/packages/vfx/shaders/flat-kit-toon-shading-and-water-143368


===============================