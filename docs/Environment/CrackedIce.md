# Cracked Ice

- https://blog.naver.com/daehuck/222228360615
[Unity Shadergraph Tutorial - Cracked Ice](https://www.youtube.com/watch?v=rlGNbq5p5CQ)
- https://80.lv/articles/how-to-build-cracked-ice-in-material-editor/

Parallax쓰면 조금 들어간것처럼 보임. - 이걸 겹겹히 쌓으면 더 깊이 들어간것처럼 보임

``` hlsl

baseColor = blend(mainTex, parallax(heightMap), 0.5)

blendNormal(Normal1, strength(Normal2(uv * 0.25), 0.25))

void Unity_NormalStrength_float(float3 In, float Strength, out float3 Out)
{
    Out = {precision}3(In.rg * Strength, lerp(1, In.b, saturate(Strength)));
}

float2 ParallaxSampling(half3 viewDirTS, half scale, float2 uv)
{
    half h = 0.217637;// pow(0.5, 2.2);
    float2 offset = ParallaxOffset1Step(h, scale, viewDirTS);
    return offset;
}

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

void ParallaxMapping_float(in float amplitude, in float numSteps, in float4 UV, in float3 viewDir, out float4 Out)
{
    float one = 1;
    float4 ParallaxedTexture = (0, 0, 0, 0);
    float4 UV2 = (0, 0, 0, 0);
    for (float d = 0.0; d < amplitude; d += amplitude / numSteps)
    {
        one = one - (1 / numSteps);
        UV2.xy = UV.xy + ParallaxSampling(viewDir, d * 0.01, UV);
        ParallaxedTexture += saturate(SAMPLE_TEXTURE2D_BIAS(_MainTex, SamplerState_Linear_Repeat, UV2.xy, 0)) * (one + (1 / numSteps));
    }
    Out = saturate(ParallaxedTexture);
}

half ParallaxMappingMask(TEXTURE2D_PARAM(maskTex, sampler_maskTex), in half2 uv, in half3 V_TS, in half parallaxOffset, in int iterCount)
{
    half one = 1;
    half parallaxedMask = 0;
    half result = 1;
    half2 parallaxUV;
    half totalOffset = 0.0;
    parallaxOffset = parallaxOffset * -0.001;

    for (int i = 0; i < iterCount; ++i)
    {
        totalOffset += parallaxOffset;
        parallaxUV = uv + half2(V_TS.x * totalOffset, V_TS.y * totalOffset);
        parallaxedMask = SAMPLE_TEXTURE2D(maskTex, sampler_maskTex, parallaxUV).r;
        result *= clamp(parallaxedMask + (i / iterCount), 0, 1);
    }

    return result;
}
```