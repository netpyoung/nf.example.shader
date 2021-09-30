# Stencil

- vert > Depth Test  > Stencil Test > Render
- frag > AlphaTest > Blending

|        |                               |                                                 |
|--------|-------------------------------|-------------------------------------------------|
| ZTest  | 깊이 버퍼 비교 후 색상 입히기 | 기본값 LEqual이기에 카메라 가까운걸 나중에 그림 |
| ZWrite | 깊이 버퍼에 쓰기 시도         | ZTest 성공해야 깊이 버퍼에 쓸 수 있음           |

|            | ZWrite On       | ZWrite Off      |
|------------|-----------------|-----------------|
| ZTest 성공 | 깊이 O / 색상 O | 깊이 X / 색상 O |
| ZTest 실패 | 깊이 X / 색상 X | 깊이 X / 색상 X |

| ZTest 예      |                    |
|---------------|--------------------|
| ZTest LEqual  | 물체가 앞에 있다   |
| ZTest Greater | 물체가 가려져 있다 |

## 템플릿

``` hlsl
// 기본값
Pass
{
    Stencil
    { 
        Ref         0      // [0 ... 255]
        ReadMask    255    // [0 ... 255]
        WriteMask   255    // [0 ... 255]
        Comp        Always
        Pass        Keep
        Fail        Keep
        ZFail       Keep
    }
    ZWrite On              // On | Off
    ZTest LEqual           // Less | Greater | LEqual | GEqual | Equal | NotEqual | Always
}
```

``` hlsl
Properties
{
    [IntRange]
    _StencilRef("Stencil ID [0-255]",      Range(0, 255)) = 0
    
    [IntRange]
    _StencilReadMask("ReadMask [0-255]",   Range(0, 255)) = 255
    
    [IntRange]
    _StencilWriteMask("WriteMask [0-255]", Range(0, 255)) = 255

    [Enum(UnityEngine.Rendering.CompareFunction)]
    _StencilComp("Stencil Comparison",     Float) = 8 // Always

    [Enum(UnityEngine.Rendering.StencilOp)]
    _StencilPass("Stencil Pass",           Float) = 0 // Keep

    [Enum(UnityEngine.Rendering.StencilOp)]
    _StencilFail("Stencil Fail",           Float) = 0 // Keep

    [Enum(UnityEngine.Rendering.StencilOp)]
    _StencilZFail("Stencil ZFail",         Float) = 0 // Keep
}

Pass
{
    Stencil
    { 
        Ref         [_StencilRef]
        ReadMask    [_StencilReadMask]
        WriteMask   [_StencilWriteMask]
        Comp        [_StencilComp]
        Pass        [_StencilPass]
        Fail        [_StencilFail]
        ZFail       [_StencilZFail]
    }
}
```

## table

| 구분      | 기본값 |                                      |
|-----------|--------|--------------------------------------|
| Ref       | -      | 버퍼에 기록                          |
| ReadMask  | 255    |                                      |
| WriteMask | 255    |                                      |
| Comp      | Always |                                      |
| Pass      | Keep   | 스텐실 테스트 성공시                 |
| Fail      | Keep   | 스텐실 테스트 실패시                 |
| ZFail     | Keep   | 스텐실 테스트 성공시 && ZTest 실패시 |

| Comp     |              | 값 |
|----------|--------------|----|
| Never    | false        | 1  |
| Less     | 버퍼 >  참조 | 2  |
| Equal    | 버퍼 == 참조 | 3  |
| LEqual   | 버퍼 >= 참조 | 4  |
| Greater  | 버퍼 <  참조 | 5  |
| NotEqual | 버퍼 != 참조 | 6  |
| GEqual   | 버퍼 <= 참조 | 7  |
| Always   | true         | 8  |

| 스텐실   |                   | 값 |
|----------|-------------------|----|
| Keep     | 변화 없음         | 0  |
| Zero     | 0                 | 1  |
| Replace  | 참조 값           | 2  |
| IncrSat  | 증가. 최대 255    | 3  |
| DecrSat  | 감소. 최소 0      | 4  |
| Invert   | 반전              | 5  |
| IncrWarp | 증가. 255면 0으로 | 6  |
| DecrWarp | 감소. 0이면 255로 | 7  |

## Ex

### 마스킹

- ZTest 실패: 깊이 X / 색상 X

``` hlsl
// 마스크.
// 일부러 비교(Comp)하지 않아서 실패상태로 만들고(Fail) Ref값을 덮어씌운다(Replace).
// 마스킹 작업이 오브젝트 보다 먼저 렌더링 되어야 함으로, 렌더큐 확인.
Stencil
{
    Ref     1
    Comp    Never
    Fail    Replace
}
```

``` hlsl
// 오브젝트.
// 앞서 마스크가 1로 덮어씌운 부분과 같은지 비교(Equal).
// 마스킹 작업이 오브젝트 보다 먼저 렌더링 되어야 함으로, 렌더큐 확인.
Stencil
{ 
    Ref     1
    Comp    Equal
}
```

### 실루엣

- 가려져 있는 물체 그리기
  - 1. 일반
    - 스텐실 버퍼 Write
  - 2. 가려지면
    - 가려져있는가 : ZTest Greater
    - 스텐실 버퍼 비교

``` hlsl
Pass
{
    Tags
    {
        "LightMode" = "SRPDefaultUnlit"
    }
    
    ZTest Greater
    ZWrite Off

    Stencil
    {
        Ref 2
        Comp NotEqual
    }
}

Pass
{
    Tags
    {
        "LightMode" = "UniversalForward"
    }

    Stencil
    {
        Ref 2
        Pass Replace
    }
}
```

## Ref

- <https://docs.unity3d.com/Manual/SL-CullAndDepth.html>
- <https://docs.unity3d.com/Manual/SL-Stencil.html>
- <https://www.ronja-tutorials.com/post/022-stencil-buffers/>
- <https://rito15.github.io/posts/unity-transparent-stencil/#스텐실>
- [유니티 URP 멀티 렌더 오브젝트 기법으로 겹쳐진면 투명화하기](https://chulin28ho.tistory.com/567)
