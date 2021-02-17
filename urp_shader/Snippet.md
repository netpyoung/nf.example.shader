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