# Billboard

## All-Axis / Spherical

- 뷰까지 오브젝트 정보(회전/확대)를 들고 가는게 아니라, 뷰공간에서 오브젝트의 정보를 더해 화면을 바라보게 만든다.

``` hlsl
float3 positionVS = TransformWorldToView(UNITY_MATRIX_M._m03_m13_m23);
positionVS += float3(IN.positionOS.xy * _Scale, 0);

OUT.positionCS = TransformWViewToHClip(positionVS);
```

## Y-Axis / Cylindrical

``` hlsl
// 개념위주, 장황하게
float3 viewDirWS = -GetWorldSpaceViewDir(UNITY_MATRIX_M._m03_m13_m23);

float toViewAngleY = atan2(viewDirWS.x, viewDirWS.z);
float s = sin(toViewAngleY);
float c = cos(toViewAngleY);
float3x3 ROTATE_Y_AXIS_M = {
    c, 0, s,
    0, 1, 0,
    -s, 0, c
};

float3 positionOS = mul(ROTATE_Y_AXIS_M, IN.positionOS.xyz);
```

``` hlsl
// 간소화
float2 viewDirWS = -normalize(
    GetCameraPositionWS().xz - UNITY_MATRIX_M._m03_m23
);

float2x2 ROTATE_Y_AXIS_M = {
    viewDirWS.y, viewDirWS.x,
    -viewDirWS.x, viewDirWS.y
};

float3 positionOS;
positionOS.xz = mul(ROTATE_Y_AXIS_M, IN.positionOS.xz);
positionOS.y = IN.positionOS.y;
```

## Ref

- <https://www.sysnet.pe.kr/2/0/11641>
- <https://en.wikibooks.org/wiki/Cg_Programming/Unity/Billboards>
- <https://80.lv/articles/the-shader-approach-to-billboarding/>
- <http://unity3d.ru/distribution/viewtopic.php?f=35&t=24903>
- <https://forum.unity.com/threads/billboard-shader-using-vertex-offsets-in-color-or-uv2-data.192652/>
- <https://gam0022.net/blog/2019/07/23/unity-y-axis-billboard-shader/>
