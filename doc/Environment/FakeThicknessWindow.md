# Fake Thickness Window

- ID맵과 Parallax(ID맵)의 겹쳐지는 부분(cross)을 이용.

``` hlsl
half2 parallaxUV = ParallaxMappingUV(_IdMaskHeightTex, sampler_IdMaskHeightTex, IN.uv, mul(TBN, V), _ParallaxScale * 0.01);

half idMaskTex = SAMPLE_TEXTURE2D(_IdMaskTex, sampler_IdMaskTex, IN.uv).r;
half idMaskParallaxTex = SAMPLE_TEXTURE2D(_IdMaskTex, sampler_IdMaskTex, parallaxUV).r;

half cross = 0;
if (idMaskTex != idMaskParallaxTex)
{
    cross = 1;
}
return half4(cross, cross, cross, 1);
```

- Parallax Mapping

``` hlsl
half2 ParallaxMappingUV(TEXTURE2D_PARAM(heightMap, sampler_heightMap), half2 uv, half3 V_TS, half amplitude)
{
    // 높이 맵에서 높이를 구하고,
    half height = SAMPLE_TEXTURE2D(heightMap, sampler_heightMap, uv).r;
    height = height * amplitude - amplitude / 2.0;

    // 시선에 대한 offset을 구한다.
    // 시선은 반대방향임으로 부호는 마이너스(-) 붙여준다.
    // TS.xyz == TS.tbn

    // TS.n에 0.42를 더해주어서 0에 수렴하지 않도록(E가 너무 커지지 않도록) 조정.
    half2 E = -(V_TS.xy / (V_TS.z + 0.42));

    // 근사값이기에 적절한 strength를 곱해주자.
    return uv + E * height;
}
```

- 라스트 오브 어스 2에서
  - ID맵 샘플 + Parallax(ID맵) 샘플 => cross section
  - 노말맵 샘플
    - diffuse는 cross section 이용해서
    - specular는 그대로
  - 환경맵 샘플
    - cross section 노말 이용.

## Ref

- <https://www.naughtydog.com/blog/naughty_dog_at_siggraph_2020>
- [SIGGRAPH 2020 - Fake Thickness - The Technical Art of The Last of Us Part II by Waylon Brinck and Steven Tang](https://youtu.be/tvBIqPHaExQ?t=2729)
- [daehuck - 라스트 오브 어스2에 쓰인 유리 쉐이더 유니티로 따라해 보기](https://blog.naver.com/daehuck/222286264294)
