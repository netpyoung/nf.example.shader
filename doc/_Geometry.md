# Gemoetry

- VS > HS > TS > `GS` > FS
- shader model 4.0
- <https://roystan.net/articles/grass-shader.html>
- <https://halisavakis.com/my-take-on-shaders-geometry-shaders/>

## Type

- <https://docs.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-geometry-shader>

``` hlsl
[maxvertexcount(NumVerts)]
void ShaderName ( PrimitiveType DataType Name [ NumElements ], inout StreamOutputObject )
{
}
```

| PrimitiveType | Num |                                                               |
|---------------|-----|---------------------------------------------------------------|
| point         | 1   | Point list                                                    |
| line          | 2   | Line list or line strip                                       |
| triangle      | 3   | Triangle list or triangle strip                               |
| lineadj       | 4   | Line list with adjacency or line strip with adjacency         |
| triangleadj   | 6   | Triangle list with adjacency or triangle strip with adjacency |

- <https://docs.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-so-type>

| StreamOutputObject |                                   |
|--------------------|-----------------------------------|
| PointStream\<T>    | A sequence of point primitives    |
| LineStream\<T>     | A sequence of line primitives     |
| TriangleStream\<T> | A sequence of triangle primitives |

## Barebone

``` hlsl
#pragma vertex vert
#pragma fragment frag
#pragma geometry geom

struct FromVS
{
    float4 positionOS : POSITION
}

struct VStoGS
{
    float4 positionOS : SV_POSITION
}

struct GStoFS
{
    float4 positionCS : SV_POSITION
}

VStoGS vert(FromVS IN)
{
}


[maxvertexcount(3)] // 최대 얼마나 많이 vertex를 추가할 것인가.
void geom(triangle float4 IN[3] : SV_POSITION, uint pid : SV_PrimitiveID, inout TriangleStream<GStoFS> STREAM)
void geom(triangle VStoGS IN[3], uint pid : SV_PrimitiveID, inout TriangleStream<GStoFS> STREAM)
{
    GStoFS OUT1;
    GStoFS OUT2;
    GStoFS OUT3;

    STREAM.Append(OUT1);
    STREAM.Append(OUT2);
    STREAM.Append(OUT3);

    // https://docs.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-so-restartstrip
    // Ends the current primitive strip and starts a new strip
    STREAM.RestartStrip();
}

half4 frag(GStoFS IN) : SV_Target
{
}
```

## Etc

- <https://medium.com/@andresgomezjr89/rain-snow-with-geometry-shaders-in-unity-83a757b767c1>
  - <https://github.com/tiredamage42/RainSnowGeometryShader>
- <https://jayjingyuliu.wordpress.com/2018/01/24/unity3d-wireframe-shader/>
