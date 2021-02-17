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
Shader Model


https://docs.unity3d.com/Manual/SL-ShaderCompileTargets.html

#pragma target 2.5 (default)
Almost the same as 3.0 target (see below), except still only has 8 interpolators, and does not have explicit LOD texture sampling.
#pragma target 3.0
OpenGL ES 2.0 devices
#pragma target 3.5 (or es3.0) + Vulkan
#pragma target 4.5 (or es3.1)

2.5: derivatives
3.0: 2.5 + interpolators10 + samplelod + fragcoord
3.5: 3.0 + interpolators15 + mrt4 + integers + 2darray + instancing
4.0: 3.5 + geometry
5.0: 4.0 + compute + randomwrite + tesshw + tessellation
4.5: 3.5 + compute + randomwrite
4.6: 4.0 + cubearray + tesshw + tessellation


https://developer.android.com/guide/topics/graphics/opengl?hl=ko
OpenGL ES 2.0 - 이 API 사양은 Android 2.2(API 레벨 8) 이상에서 지원됩니다.
OpenGL ES 3.0 - 이 API 사양은 Android 4.3(API 레벨 18) 이상에서 지원됩니다.
OpenGL ES 3.1 - 이 API 사양은 Android 5.0(API 레벨 21) 이상에서 지원됩니다.

https://source.android.com/setup/start/build-numbers?hl=ko
Froyo 	2.2.x 	API 수준 8, NDK 4
Jelly Bean 	4.3.x 	API 수준 18
Lollipop 	5.0 	API 수준 21
Nougat 	7.0 	API 수준 24

https://developer.android.com/ndk/guides/graphics/getting-started?hl=ko
Vulkan API 수준 24

2018 노트8
안드로이드 7.1 (Nougat) → 8.0 (Oreo) → 9 (Pie)
2016 노트7
안드로이드 6.0 (Marshmallow)
2015 노트5
안드로이드 5.1 (Lollipop) → 6.0 (Marshmallow) → 7.0 (Nougat)
2014 노트4
안드로이드 4.4 (KitKat) → 5.0[2] → 5.1 (Lollipop) → 6.0 (Marshmallow)

https://forum.unity.com/threads/severe-banding-with-webgl-on-chrome.310326/#post-2035482
WebGL == OpenGL ES 2.0

https://blog.mozilla.org/futurereleases/2015/03/03/an-early-look-at-webgl-2/
ES 3.0 target to WebGL 2
