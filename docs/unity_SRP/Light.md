# Light

반사
Reflect probe : 주변의 Static오브젝트들을 캡쳐하여 CubeMap데이터로 저장

- `_MainLightPosition` 이라고 병신같은 이름이 있는데, 실제 메인 라이트는 위치정보를 가지고 있지 않다. 방향정보이다.
  - 인스펙터에서 암만 position값을 가지고 바꿔봐도 안바뀜. rotation을 움직이면 바뀜.
  - GameObject rotation X : 0도 ~ 90도 => light.direction.y :0 ~ 1

// [커스텀쉐이더에서 리플렉션 프로브 사용하기 (Using Reflection Probes in Custom Shader)](https://ozlael.tistory.com/38)

``` hlsl
float3 reflectVec = reflect(-viewDir, normalOS);
float3 probe0 = DecodeHDREnvironment(SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectVec, lod), unity_SpecCube0_HDR);
float3 probe1 = DecodeHDREnvironment(SAMPLE_TEXTURECUBE_LOD(unity_SpecCube1, samplerunity_SpecCube1, reflectVec, lod), unity_SpecCube1_HDR);
float3 probe = lerp(probe1, probe0, unity_SpecCube0_BoxMin.w);
```

- 유니티 Skybox 설정 : `Window > Rendering > Lighting > Environment`
  - `unity_SpecCube0`가 위에서 설정된 메테리얼로 스카이박스를 렌더링함.(`Camera > Background Type`과는 상관없음)

주변광
Light probe GI(Global Illumination)

``` hlsl


float3 shadergraph_LWBakedGI(float3 positionWS, float3 normalWS, float2 uvStaticLightmap, float2 uvDynamicLightmap, bool applyScaling)
{
#ifdef LIGHTMAP_ON
    if (applyScaling)
        uvStaticLightmap = uvStaticLightmap * unity_LightmapST.xy + unity_LightmapST.zw;

    return SampleLightmap(uvStaticLightmap, normalWS);
#else
    return SampleSH(normalWS);
#endif
}


void shadergraph_LWFog(float3 position, out float4 color, out float density)
{
    color = unity_FogColor;
    #if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
    // ComputeFogFactor returns the fog density (0 for no fog and 1 for full fog).
    density = ComputeFogFactor(TransformObjectToHClip(position).z);
    #else
    density = 0.0f;
    #endif
}
```

## code

``` hlsl
// Light & Shadow
#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
#pragma multi_compile _ _ADDITIONAL_LIGHTS
#pragma multi_compile _ _ADDITIONAL_LIGHTS_CASCADE
#pragma multi_compile _ _SHADOWS_SOFT
```

``` hlsl
Light mainLight = GetMainLight();
Light mainLight = GetMainLight(shadowCoord);
```

``` hlsl
OUT.shadowCoord   = TransformWorldToShadowCoord(OUT.positionWS);// float4
```

``` hlsl
VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
OUT.shadowCoord = GetShadowCoord(vertexInput);
```

``` hlsl
// com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl

struct Light
{
    half3   direction;
    half3   color;

    // 범위각(AngleAttenuation)에 의한 빛의 감쇠(Directional은 1)
    half    distanceAttenuation; 

    // RealtimeShadow 어두움.
    half    shadowAttenuation;
};

Light GetMainLight()
Light GetMainLight(float4 shadowCoord)
Light GetMainLight(float4 shadowCoord, float3 positionWS, half4 shadowMask)

Light GetAdditionalPerObjectLight(int perObjectLightIndex, float3 positionWS)

int GetAdditionalLightsCount()

Light GetAdditionalLight(uint i, float3 positionWS)
Light GetAdditionalLight(uint i, float3 positionWS, half4 shadowMask)
```

## LightMap

``` hlsl
// LightMap
#pragma multi_compile _ DIRLIGHTMAP_COMBINED
#pragma multi_compile _ LIGHTMAP_ON
```

``` hlsl
Pass
{
    Tags
    {
        "LightMode" = "Meta"
    }
}

struct Attributes
{
    float2 lightmapUV : TEXCOORD1; // 자동생성
};

struct Varyings
{
    float2 lightmapUV : TEXCOORD1;
}

OUT.lightmapUV = IN.lightmapUV * unity_LightmapST.xy + unity_LightmapST.zw;
```

## GI

- GI
  - indirectDiffuse
    - 라이트맵이 있으면 라이트맵으로 계산
    - 없으면 VertexSH + PixelSH로 계산
  - indirectSpecular
    - Cube맵으로 계산. BRDF데이터와 GlossyEnvironemtReflection

``` hlsl
// SH(Spherical Harmonics)
// 노멀방향의 GI Ambient를 얻어옴
half3 ambient = SampleSH(IN.normal);

half3 bakedGI = SAMPLE_GI(IN.lightmapUV, vertexSH, N);
MixRealtimeAndBakedGI(mainLight, N, bakedGI, half4(0, 0, 0, 0));

// Define키워드 확인이 어려울 경우, 직접 구하는거 고려할것
// bakedGI = SubtractDirectMainLightFromLightmap(light, normalWS, bakedGI);


half3 indirectDiffuse = bakedGI * occlusion;
half3 indirectSpecular = GlossyEnvironemtReflection(R, brdfData.perceptualRoughness, occlusion);
```

``` hlsl
void MixRealtimeAndBakedGI(inout Light light, half3 normalWS, inout half3 bakedGI)
{
#if defined(LIGHTMAP_ON) && defined(_MIXED_LIGHTING_SUBTRACTIVE)
    bakedGI = SubtractDirectMainLightFromLightmap(light, normalWS, bakedGI);
#endif
}
```

TODO occlusion?

## Reflection Probe

| TimeSlicing       |          | (렌더링 프레임네 스크립트를 통해 새로고침 호출은 무시)                                                     |
| ----------------- | -------- | ---------------------------------------------------------------------------------------------------------- |
| All Faces at once | 9 Frame  | 6면(1 Frame x 1), 1레벨 밉맵은 각각 프레임마다(1 Frame x 6), 나머지 밉맵들(1 Frame), 큐브맵 복사(1 Frame). |
| Individual Faces  | 14 Frame | 6면(1 Frame x 6), 1레벨 밉맵은 각각 프레임마다(1 Frame x 6), 나머지 밉맵들(1 Frame), 큐브맵 복사(1 Frame). |
| No Time Slicing   | 1 Frame  |                                                                                                            |


## TOOD lightmap

- https://chulin28ho.tistory.com/441?category=458928