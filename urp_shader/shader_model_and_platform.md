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

| #pragma target | 설명            |                                  |
|----------------|-----------------|----------------------------------|
| 2.5            | 기본값 / WebGL1 |                                  |
| 3.0            | WebGL2          |                                  |
| 3.5            | es3.0  / Vulkan |                                  |
| 4.0            |                 | Geometry                         |
| 4.5            | es3.1           | Compute                          |
| 4.6            |                 | Tessellation(* Metal은 지원안함) |
| 5.0 | | RenderTexture.enableRandomWrite|
## 안드로이드와 그래픽 라이브러리

| Graphic Library | Android API | version | 코드명     | Linear지원 |
|-----------------|-------------|---------|------------|------------|
| es2.0           | 8           | 2.2.x   | Froyo      | x          |
| es3.0           | 18          | 4.3.x   | Jelly Bean | O          |
| es3.1           | 21          | 5.0     | Lollipop   | O          |
| Vulkan          | 24          | 7.0     | Nougat     | O          |

## Linear지원 사양

| platform | Graphic Library        | version                                 |
|----------|------------------------|-----------------------------------------|
| Android  | OpenGL ES 3.0 / Vulkan | Android 4.3 / API level 18 / Jelly Bean |
| iOS      | Metal                  | 8.0                                     |

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