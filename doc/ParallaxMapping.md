# Parallax Mapping

- parallax mapping, offset mapping, photonic mapping, virtual displace mapping 이라고 부른다.
- 높이 정보를 활용하여 텍스처 좌표를 보정.

- <https://learnopengl.com/Advanced-Lighting/Parallax-Mapping>
  - 번역본: <https://gyutts.tistory.com/175>
- <https://bzyzhang.github.io/2020/11/29/2020-11-29-（三）表面凹凸技术/>
- <http://blog.naver.com/sybershin/129399930>

``` hlsl
half3x3 TBN = half3x3(normalInputs.tangentWS, normalInputs.bitangentWS, normalInputs.normalWS);

// 시점에 대한 tangent space의 V
OUT.V_TS = mul(TBN, GetCameraPositionWS() - vertexInputs.positionWS);
// 광원 계산을 위한 tangent space의 L
OUT.L_TS = mul(TBN, mainLight.direction);


half2 ParallaxMapping(half2 uv, half3 V_TS)
{
    // 높이 맵에서 높이를 구하고,
    half height = SAMPLE_TEXTURE2D(_NormalDepthPackedTex, sampler_NormalDepthPackedTex, uv).b;

    // 시선에 대한 offset을 구한다.
    // 시선은 반대방향임으로 부호는 마이너스(-) 붙여준다.
    half2 E = -(V_TS.xy / V_TS.z);

    // 근사값이기에 적절한 strength를 곱해주자.
    return uv + E * (height * _HeightStrength);
}

half3 L_TS = normalize(IN.L_TS);
half3 V_TS = normalize(IN.V_TS);
half2 uv = ParallaxMapping(IN.uv, V_TS);
if ((uv.x < 0.0 || 1.0 < uv.x) || (uv.y < 0.0 || 1.0 < uv.y))
{
    // x, y가 범위([0, 1])를 벗어나면 discard.
    discard;
}

// tangent space기준으로 반사 계산을 한다.
half3 N_TS = UnpackNormal(SAMPLE_TEXTURE2D(_NormalDepthPackedTex, sampler_NormalDepthPackedTex, uv));
half NdotL = saturate(dot(N_TS, L_TS));
```

## 종류

- Parallax Mapping
- Parallax Mapping with offset limit
- Steep Parallax Mapping
- ReliefParallax
- Parallax Occlusion Mapping (POM)
- ....
