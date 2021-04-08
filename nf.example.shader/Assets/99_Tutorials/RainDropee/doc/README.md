# rainy surface shader for unity

## Ref

- <https://deepspacebanana.github.io/blog/shader/art/unreal%20engine/Rainy-Surface-Shader-Part-1>
- <https://deepspacebanana.github.io/blog/shader/art/unreal%20engine/Rainy-Surface-Shader-Part-2>
- [The Technical Art of The Last of Us Part II by Waylon Brinck and Steven Tang || SIGGRAPH 2020 - Rain on Glass](https://youtu.be/tvBIqPHaExQ?t=2591)

## desc

![Texture_Packing.jpg](./Texture_Packing.jpg)
    
| Channel |                 |
|---------|-----------------|
| r       | droplet         |
| g       | streaks         |
| b       | streak gradient |
| a       | -               |

- R채널을 이용하여 물방울(원) 표시 2개를 번갈아 표시
- G채널을 이용하여 옆면 물흐름 무늬
- B채널을 이용 [panning](https://en.wikipedia.org/wiki/Panning_(camera))효과

``` hlsl
frac(x)
// - 시간 범위를 0 ~ 1사이로 한정
// - `abs(sin(x))`
// - 페이드인 아웃

yGradient = mul(half3(0, 0, 1), TBN).y
// Tangent 공간의 z값 : 표면의 수직
// WorldSpace공간으로 변환 후 y값을 이용하여 기울기(gradient)를 얻음

lerp(dropletNormalTS, streakNormal, yGradient)
// 이 기울기를 이용하여, 물방울이 보이게 할지, 물줄기가 보이기 할 지 결정.

BlendNomral(x)
// com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl
// Tangent 공간상의 노멀값 섞기
// Main 노말과 물방울 및 물줄기 노말을 섞는다.
```

``` hlsl
// 물방울 구하기

half dropletTime1 = time * _RainSpeed;

// // frac: 소수점이하 리턴.
//    frac(x) : 0 ~ 0.9999999
// 1- frac(x) : 1 ~ 0.00000
half emissive1 = (1 - frac(dropletTime1));
half droplet1 = SAMPLE_TEXTURE2D(_DropletPatternPackTex, sampler_DropletPatternPackTex, IN.uv).r - emissive1;
half edgeMask1 = EdgeMask(droplet1, _EdgeWidth);
half rippleFade1 = RippleFade(dropletTime1);


inline half EdgeMask(half droplet, half edgeWidth)
{
    // 내부에 작은 검은 마스크를 만들어 결과적으로 흰색 테두리 효과.

    // 0  0.05        0.95 1
    // |--|--------------|-|
    // 검                 흰

    // smoothstep(min, max, x);
    // - [min, max]사이의 Hermite 보간

    // 0.04 ~ 0 | 0 ~ 0.05 ~ 0.9 | 0.9 ~ 0.95 // distance 0.05
    // 0        | 0 ~ 1    ~ 18  | 18  ~ 19   // divide   0.05
    // 0        | 0 ~ 1          | 1          // smoothstep
    // 1        | 1 ~ 0          | 0          // 1 - x
    return 1 - smoothstep(0, 1, distance(droplet, 0.05) / edgeWidth);
}

inline half RippleFade(half dropletTime)
{                
    // ripple: 잔물결
    // 시간에따른 Fade in / out 효과
    // sin PI값을 사용.
    // | 0 | 1    | 0  |
    // | 0 | PI/2 | PI |
    return abs(sin(dropletTime * PI));
}
```