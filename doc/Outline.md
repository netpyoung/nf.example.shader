# Outline

- 2-pass
  - Scale 확장
  - Normal 확장
- Rim
- SSO(Screen Space Outline)

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
OUT.positionCS = TransformObjectToHClip(IN.positionOS);

half4 normalCS = TransformObjectToHClip(IN.normal);

// 아웃라인은 2차원이므로. `normalCS.xy`에 대해서만 계산 및 `normalize`.
// 카메라 거리에 따라 아웃라인의 크기가 변경되는것을 막기위해 `positionCS.w`를 곱해준다.
// _ScreenParams.xy (x/y는 카메라 타겟텍스쳐 넓이/높이)로 나누어서 [-1, +1] 범위로 만듬.
// 길이 2인 범위([-1, +1])와 비율을 맞추기 위해 OutlineWidth에 `*2`를 해준다.

half2 offset = (normalize(normalCS.xy) * normalCS.w) / _ScreenParams.xy * (2 * _OutlineWidth) * OUT.positionCS.w;

// 버텍스 칼라를 곱해주면서 디테일 조정.
// offset *= IN.color.r;
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

## Post Processing 이용 - SSO(Screen Space Outline)

- <https://en.wikipedia.org/wiki/Roberts_cross>
- <https://en.wikipedia.org/wiki/Sobel_operator>

### 외곽선 검출(Edge detection) 필터

|                |                                  |
| -------------- | -------------------------------- |
| 색성분 엣지    | 밝기차                           |
| ID 엣지        | 알파값에 id: 1, 0이런식으로 넣기 |
| 깊이 엣지      | 깊이 맵 필요                     |
| 법선 엣지      | 노말 맵 필요                     |
| 확대 모델 엣지 | 셰이더 2패스                     |

## Ref

- <https://roystan.net/articles/outline-shader.html>
- <https://alexanderameye.github.io/outlineshader.html>
- <https://alexanderameye.github.io/notes/rendering-outlines/>
- <https://musoucrow.github.io/2020/07/05/urp_outline/>
- <https://github.com/netpyoung/bs.introduction-to-shader-programming/blob/master/note/ch12.md>
- <https://www.ronja-tutorials.com/2020/07/23/sprite-outlines.html>
- <https://bgolus.medium.com/the-quest-for-very-wide-outlines-ba82ed442cd9>
- <https://www.codinblack.com/outline-effect-using-shader-graph-in-unity3d/>
- [외곽선 렌더링 구현에 관한 허접한 정리](https://gamedevforever.com/18)
