# Dissolve

Dissolve텍스쳐를 이용하여, 특정 값 이하일때 표시를 안하면 사라지는 효과를 얻을 수 있다.

``` hlsl
half cutout = SAMPLE_TEXTURE2D(_TexDissolve, sampler_TexDissolve, IN.uv).r;
clip(cutout - _Amount);
```

``` hlsl
// https://developer.download.nvidia.com/cg/clip.html

void clip(float4 x)
{
  if (any(x < 0))
    discard;
}
```

- 유니티 함수 `AlphaDiscard`를 쓰는 사람도 있는데, 이 경우 `_ALPHATEST_ON`를 이용하는지 여부에 따라 결과가 달라짐으로 주의.

``` hlsl
// com.unity.render-pipelines.universal/ShaderLibrary/ShaderVariablesFunctions.hlsl

void AlphaDiscard(real alpha, real cutoff, real offset = real(0.0))
{
    #ifdef _ALPHATEST_ON
        clip(alpha - cutoff + offset);
    #endif
}
```
