# Color Grading LUT

- [http://ttmayrin.tistory.com/34](https://web.archive.org/web/20120213004214/http://ttmayrin.tistory.com/34)

``` hlsl
float3 CalcLUT2D( sampler InLUT, float3 InColor )
{
    // requires a volume texture 16x16x16 unwrapped in a 2d texture 256x16
    // can be optimized by using a volume texture
    float2 Offset = float2(0.5f / 256.0f, 0.5f / 16.0f);
    float Scale = 15.0f / 16.0f; 

    // Also consider blur value in the blur buffer written by translucency
    float IntB = floor(InColor.b * 14.9999f) / 16.0f;
    float FracB = InColor.b * 15.0f - IntB * 16.0f;

    float U = IntB + InColor.r * Scale / 16.0f;
    float V = InColor.g * Scale;

    float3 RG0 = tex2D( InLUT, Offset + float2(U               , V) ).rgb;
    float3 RG1 = tex2D( InLUT, Offset + float2(U + 1.0f / 16.0f, V) ).rgb;

    return lerp( RG0, RG1, FracB );
}

float3 CalcLUT3D( sampler InLUT, float3 InColor )
{
    return tex3D( InLUT, InColor * 15.f / 16.f + 0.5f / 16.f ).rgb;
}
```

## Ref

- [DirectX Shader LUT 필터 코드 구현](https://nellfamily.tistory.com/51)
- [[Unite Seoul 2019] 최재영 류재성 - 일곱개의 대죄 : "애니메이션의 감성을 그대로＂와 “개발 최적화"](https://youtu.be/0LwlNVS3FJo?t=1087)
