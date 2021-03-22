https://roystan.net/articles/grass-shader.html

#pragma hull hull
https://catlikecoding.com/unity/tutorials/advanced-rendering/tessellation/

// VS > HS > TS > GS > FS

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