---

layout: post
title: 'outline'
tags: outline , 아웃라인

---

# Outline

- 2-pass
  - Scale 확장
  - Normal 확장
- Rim
- Post Processing

## 2-pass

``` hlsl
Tags
{
    "RenderPipeline" = "UniversalRenderPipeline"
}

Pass
{
    Name "Outline"
    Tags
    {
        "LightMode" = "SRPDefaultUnlit"
        "Queue" = "Geometry"
        "RenderType" = "Opaque"
    }
    Cull Front
    
    HLSLPROGRAM
    // outline code
    ENDHLSL
}

Pass
{
    Name "Front"
    Tags
    {
        "LightMode" = "UniversalForward"
        "Queue" = "Geometry"
        "RenderType" = "Opaque"
    }
    Cull Back

    HLSLPROGRAM
    // render code
    ENDHLSL
}
```

### Scale 확장

- 1pass 원래 Model 확대하여 외곽선 색으로 칠한다
- 2pass 원래 Model을 덧그린다

``` hlsl
half4 Scale(half4 positionOS, half3 s)
{
    // s : scale
    // m : scale matrix

    half4x4 m;
    m[0][0] = 1.0 + s.x; m[0][1] = 0.0;       m[0][2] = 0.0;       m[0][3] = 0.0;
    m[1][0] = 0.0;       m[1][1] = 1.0 + s.y; m[1][2] = 0.0;       m[1][3] = 0.0;
    m[2][0] = 0.0;       m[2][1] = 0.0;       m[2][2] = 1.0 + s.z; m[2][3] = 0.0;
    m[3][0] = 0.0;       m[3][1] = 0.0;       m[3][2] = 0.0;       m[3][3] = 1.0;
    return mul(m, positionOS);
}

OUT.positionCS = TransformObjectToHClip(Scale(IN.positionOS, _OutlineScale).xyz);
```

### Normal 확장

- <https://www.videopoetics.com/tutorials/pixel-perfect-outline-shaders-unity/>
- [마둠파 - 유니티 외곽선 셰이더 완벽정리편](https://blog.naver.com/mnpshino/221495979665)

``` hlsl
half3 N = TransformObjectToWorldNormal(IN.normal);
half4 normalCS = TransformWorldToHClip(N);

// 아웃라인은 2차원이므로. `normalCS.xy`에 대해서만 계산 및 `normalize`.
// 카메라 거리에 따라 아웃라인의 크기가 변경되는것을 막기위해 `normalCS.w`를 곱해준다.
// _ScreenParams.xy (x/y는 카메라 타겟텍스쳐 넓이/높이)로 나누어서 [-1, +1] 범위로 만듬.
// 길이 2인 범위([-1, +1])와 비율을 맞추기 위해 OutlineWidth에 `*2`를 해준다.

half2 offset = (normalize(normalCS.xy) * normalCS.w) / _ScreenParams.xy * (2 * _OutlineWidth);

// 버텍스 칼라를 곱해주면서 디테일 조정.
// offset *= IN.color.r;

OUT.positionCS = TransformObjectToHClip(IN.positionOS);
OUT.positionCS.xy += offset;
```

- 여러 갈래로 흩어진 normal을 부드럽게 하기
  - `.fbx -> Model, Normal & Tangent Normals -> Normals:Calculate, Smoothing Angel:180`
  - [TCP2 : Smoothed Normals Utility](https://assetstore.unity.com/packages/vfx/shaders/toony-colors-pro-2-8105)

## Rim

- 림라이트 효과를 이용

``` hlsl
half3 NdotL = normalize(N, L);
half rim = abs(NdotL);
if (rim > _Outline)
{
    rim = 1;
}
else
{
    rim = -1;
}
final.rgb *= rim;
```

``` hlsl
half3 NdotV = normalize(N, V);
half rim = 1 - NdotV;
final.rgb *= pow(rim, 3);
```

## Post Processing

- <https://roystan.net/articles/outline-shader.html>
- <https://alexanderameye.github.io/outlineshader.html>
- <https://musoucrow.github.io/2020/07/05/urp_outline/>
- <https://docs.unity3d.com/Manual/SL-CameraDepthTexture.html>


`_CameraColorTexture`
`_CameraDepthNormalsTexture`

- UniversalRenderPipelineAsset.asset > General > Depth Texture




### 외곽선 검출 필터

- <https://github.com/netpyoung/bs.introduction-to-shader-programming/blob/master/note/ch12.md>
- <https://en.wikipedia.org/wiki/Sobel_operator>
- <https://www.ronja-tutorials.com/2020/07/23/sprite-outlines.html>
  
  https://medium.com/@bgolus/the-quest-for-very-wide-outlines-ba82ed442cd9

https://www.codinblack.com/outline-effect-using-shader-graph-in-unity3d/


- BRDF이용



- https://assetstore.unity.com/packages/tools/particles-effects/highlighting-system-41508#content


https://github.com/unity3d-jp/UnityChanToonShaderVer2_Project/blob/release/urp/2.2/Runtime/Shaders/UniversalToonOutline.hlsl



1. 캐릭터 등의 어차피 SRP Batcher가 작동하지 않는 오브젝트에서는 코드에 아웃라인 패스를 삽입하여 머티리얼별로 제어를 해 주도록 하자
2. 배경 등의 오브젝트에 외곽선을 그릴일이 있고 멀티-서브 머티리얼을 사용하지 않는다면 강제로 두번째 머티리얼을 사용해 주자.
3. 배경 등의 오브젝트에 외곽선을 그릴일이 있고 멀티-서브 머티리얼을 사용한다면 렌더오브젝트 - 오버라이드 머티리얼을 사용하자.
​[출처] UPR 셰이더 코딩 튜토리얼 : 제 2편 - SRP Batcher와 MultiPass Outline|작성자 Madumpa

- [외곽선 렌더링 구현에 관한 허접한 정리](https://gamedevforever.com/18)
- <https://gpgstudy.com/forum/viewtopic.php?t=5869>

- edge 검출 - https://developer.nvidia.com/gpugems/gpugems3/part-iv-image-effects/chapter-23-high-speed-screen-particles