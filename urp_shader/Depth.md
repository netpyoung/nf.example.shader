# Depth

``` hlsl
half3 perspectiveDivide = IN.positionNDC.xyz / IN.positionNDC.w;
half2 uv_Screen         = perspectiveDivide.xy;

half  sceneRawDepth     = SampleSceneDepth(uv_Screen);
half  sceneEyeDepth     = LinearEyeDepth(sceneRawDepth, _ZBufferParams);
half  scene01Depth      = Linear01Depth (sceneRawDepth, _ZBufferParams);
```

## SV_Depth

- `half4 frag (in VStoFS IN) : SV_Target`
- 메쉬에서 직접 계산. SV_Depth를 이용하여 조정할 수 있음.

``` hlsl
struct OutputFS
{
    half4 color : SV_Target;
    half  depth : SV_Depth;
    // SV_DepthGreaterEqual
    // SV_DepthLessEqual
};

OutputFS frag (in VStoFS IN)
{
    OutputFS OUT;
    OUT.color = color;
    OUT.depth = depth;
    return OUT;
}
```

|          | UNITY_REVERSED_Z | UNITY_NEAR_CLIP_VALUE | UNITY_RAW_FAR_CLIP_VALUE |
|----------|------------------|-----------------------|--------------------------|
| OpenGL   | 0                | (-1.0)                | (1.0)                    |
| Direct3D | 1                | (1.0)                 | (0.0)                    |

| Orthographic depth | near plane | far plane |
|--------------------|------------|-----------|
| OpenGL             | 0          | 1         |
| Direct3D           | 1          | 0         |

| Perspective depth | near plane | far plane |
|-------------------|------------|-----------|
| OpenGL            | -near      | far       |
| Direct3D          | near       | 0         |

| _ZBufferParams | x             | y        | z     | w     |
|----------------|---------------|----------|-------|-------|
| OpenGL         | 1 - far/near  | far/near | x/far | y/far |
| Direct3D       | -1 + far/near | 1        | x/far | 1/far |

## Normalised Device Coordinates (NDC)

|     | xy                                |
|-----|-----------------------------------|
| NDC | 화면좌표 [좌하(0, 0) ~ 우상(1,1)] |

``` hlsl
// NDC
float4 positionNDC = positionCS * 0.5f;
positionNDC.xy     = float2(positionNDC.x, positionNDC.y * _ProjectionParams.x) + positionNDC.w;
positionNDC.zw     = positionCS.zw;
OUT.positionNDC    = positionNDC;
```


## xxx

|                            | 0          | 1              |
|----------------------------|------------|----------------|
| SampleSceneDepth - OpenGL  | near plane | far plane      |
| SampleSceneDepth - DirectX | far plane  | near plane     |
| Linear01Depth              | camera pos | far plane      |
| LinearEyeDepth             | camera pos | Viewspace unit |

## Reconstruct

``` hlsl
// orthographic

// FS
half orthoLinearDepth = _ProjectionParams.x > 0 ? sceneRawDepth : 1 - sceneRawDepth;
half sceneEyeDepth = lerp(_ProjectionParams.y, _ProjectionParams.z, orthoLinearDepth);
```

``` hlsl
// perspective

// VS
OUT.viewDirWS = _WorldSpaceCameraPos - positionWS;

// FS
half sceneEyeDepth = LinearEyeDepth(sceneRawDepth, _ZBufferParams);
half fragmentEyeDepth = -IN.positionVS.z;
half3 worldPos = _WorldSpaceCameraPos - ((IN.viewDirWS / fragmentEyeDepth) * sceneEyeDepth);
```

## 키워드

- UNITY_REVERSED_Z
- UNITY_NEAR_CLIP_VALUE
- UNITY_RAW_FAR_CLIP_VALUE 

|          |                              |
|----------|------------------------------|
| EyeDepth | 카메라평면에서 물체까지 거리 |





float fragmentEyeDepth = -IN.positionVS.z;


월드좌표 : (월드 위치값xy, 월드깊이값z) => 해당 월드좌표가 박스영역안에 있으면 데칼.
https://github.com/o-l-l-i/ScreenSpaceDecal/blob/master/ScreenSpaceDecal.shader


https://forum.unity.com/threads/decodedepthnormal-linear01depth-lineareyedepth-explanations.608452/#post-4070806
LinearEyeDepth takes the depth buffer value and converts it into world scaled view space depth
0.0 will become the far plane distance value, and 1.0 will be the near clip plane


EyeDepth 카메라 좌표기준 평면에서 직각으로 오브젝트까지 선을그은 거리

Linear01Depth
Linear01Depth mostly just makes the non-linear 1.0 to 0.0 range be a linear 0.0 to 1.0, 


원근 분할(Perspective Divide)



https://github.com/keijiro/DepthInverseProjection


    Direct3D-like, Reversed Z Buffer : 1 at the near plane, 0 at the far plane
    OpenGL-like, Z Buffer : 0 at the near plane, 1 at the far plane

