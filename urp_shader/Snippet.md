https://catlikecoding.com/unity/tutorials/rendering/part-4/
DotClamped

``` hlsl
inline half DotClamped (half3 a, half3 b) {
    #if (SHADER_TARGET < 30 || defined(SHADER_API_PS3))
        return saturate(dot(a, b));
    #else
        return max(0.0h, dot(a, b));
    #endif
}
```

Unity_SafeNormalize

https://forum.unity.com/threads/vertex-shader-normalized-2d-vertex-position-on-unit-circle-mesh-produces-wrong-normalization-result.641272/#post-4299088

rsqrt - https://developer.download.nvidia.com/cg/rsqrt.html

```
inline float3 Unity_SafeNormalize(float3 inVec)
{
    float dp3 = max(0.001f, dot(inVec, inVec));
    return inVec * rsqrt(dp3);
}
```


com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl

Gamma / Linear color space

``` hlsl
// legacy

#ifdef UNITY_COLORSPACE_GAMMA
#   define unity_LightGammaCorrectionConsts_PIDiv4 ((UNITY_PI/4)*(UNITY_PI/4))
#   define unity_LightGammaCorrectionConsts_HalfDivPI ((.5h/UNITY_PI)*(.5h/UNITY_PI))
#   define unity_LightGammaCorrectionConsts_8 (8*8)
#   define unity_LightGammaCorrectionConsts_SqrtHalfPI (2/UNITY_PI)
#else
#   define unity_LightGammaCorrectionConsts_PIDiv4 (UNITY_PI/4)
#   define unity_LightGammaCorrectionConsts_HalfDivPI (.5h/UNITY_PI)
#   define unity_LightGammaCorrectionConsts_8 (8)
#   define unity_LightGammaCorrectionConsts_SqrtHalfPI (0.79788)
#endif
```


FresnelLerp() UnityStandardBRDF.cginc




=========
MSAA - Multi-Sampling Anti-Aliasing의 
FFR - https://developer.oculus.com/documentation/native/android/mobile-ffr/
=========
ColorMask 0 은 모야

=========
GrabPass

BlitPass


| texture                |                              |
|------------------------|------------------------------|
| _CameraDepthTexture    |                              |
| _CameraDepthAttachment |                              |
| _CameraNormalsTexture  |                              |SampleSceneDepth
| _CameraOpaqueTexture   | 불투명 채널에서 렌더링 된 후 | SceneColor
| _CameraColorTexture    | 반투명 채널이 렌더링 된 후   |

### 주의
  - `_CameraColorTexture`
    - PipelineAsset> Quality> Anti Aliasing (MSAA)> 2x 이상.

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