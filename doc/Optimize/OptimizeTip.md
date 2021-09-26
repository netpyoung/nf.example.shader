# Optimize tip

## from [Optimizing unity games (Google IO 2014)](https://www.slideshare.net/AlexanderDolbilov/google-i-o-2014)

- Shader.SetGlobalVector
- OnWillRenderObject(오브젝트가 보일때만), propertyID(string보다 빠름)

``` cs
void OnWillRenderObject()
{
    material.SetMatrix(propertyID, matrix);
}
```

## Tangent Space 라이트 계산

- 월드 스페이스에서 라이트 계산값과 탄젠트 스페이스에서 라이트 계산값과 동일.
- vertex함수에서 tangent space V, L을 구하고 fragment함수에 넘겨줌.
  - 월드 스페이스로 변환 후 계산하는 작업을 단축 할 수 있음

## 데미지폰트

- 셰이더로 한꺼번에 출력
- <https://blog.naver.com/jinwish/221577786406>

## Chroma subsampling

- 텍스쳐 압축시 품질 손상이 일어나는데 그걸 줄이는 기법 중 하나
- <https://en.wikipedia.org/wiki/Chroma_subsampling>
- <https://github.com/keijiro/ChromaPack>
- YCbCr

## NPOT 지원안하는 텍스쳐 포맷

- NPOT지원안하는 ETC/PVRTC같은경우 POT로 자르고 셰이더로 붙여주는걸 작성해서 최적화
  - <https://blog.naver.com/jinwish/221576705990>

## GGX 공식 간략화

- Optimizing PBR for Mobile
  - [pdf](https://community.arm.com/cfs-file/__key/communityserver-blogs-components-weblogfiles/00-00-00-20-66/siggraph2015_2D00_mmg_2D00_renaldas_2D00_slides.pdf), [note](https://community.arm.com/cfs-file/__key/communityserver-blogs-components-weblogfiles/00-00-00-20-66/siggraph2015_2D00_mmg_2D00_renaldas_2D00_notes.pdf)

## Vertex Lighting 합

- [SIGGRAPH2011 - Dynamic lighting in God of War 3](https://advances.realtimerendering.com/s2011/index.html)
  - [Comments on Advances in Real Time Rendering 2011](http://www.thetenthplanet.de/archives/1337)

``` hlsl
// ref: https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl

half3 VertexLighting(float3 positionWS, half3 normalWS)
{
    half3 vertexLightColor = half3(0.0, 0.0, 0.0);

#ifdef _ADDITIONAL_LIGHTS_VERTEX
    uint lightsCount = GetAdditionalLightsCount();
    LIGHT_LOOP_BEGIN(lightsCount)
        Light light = GetAdditionalLight(lightIndex, positionWS);
        half3 lightColor = light.color * light.distanceAttenuation;
        vertexLightColor += LightingLambert(lightColor, light.direction, normalWS);
    LIGHT_LOOP_END
#endif

    return vertexLightColor;
}
```

``` hlsl
struct VStoFS
{
    half4 positionCS          : SV_POSITION;
    half2 uv                  : TEXCOORD0;
    half3 N                   : TEXCOORD1;
    half3 H_Sun               : TEXCOORD2;
    half3 H_Points            : TEXCOORD3;
    half3 Diffuse_Sun         : TEXCOORD4;
    half3 Diffuse_Points      : TEXCOORD5;
};

VStoFS vert(in APPtoVS IN)
{
    half3 L_points = half3(0, 0, 0);

    uint additionalLightsCount = min(GetAdditionalLightsCount(), 3);
    for (uint i = 0; i < additionalLightsCount; ++i)
    {
        Light additionalLight = GetAdditionalLight(i, positionWS);
        half3 L_attenuated = additionalLight.direction * additionalLight.distanceAttenuation;

        OUT.Diffuse_Points += saturate(dot(N, L_attenuated)) * saturate(additionalLight.color);
        L_points += L_attenuated;
    }
    OUT.H_Points = normalize(L_points) + V;

    OUT.Diffuse_Sun = saturate(dot(N, L * mainLight.distanceAttenuation)) * mainLight.color;
    OUT.H_Sun = normalize(L + V);
}

half4 frag(in VStoFS IN) : SV_Target
{
{
    half3 diffuse = diffuseTex * (IN.Diffuse_Sun + IN.Diffuse_Points);

    half2 highlights;
    highlights.x = pow(saturate(dot(N, H_Sun)), _SpecularPower);
    highlights.y = pow(saturate(dot(N, H_Points)), _SpecularPower);
    half3 specular = specularMaskTex * ((IN.Diffuse_Sun * highlights.x) + (IN.Diffuse_Points * highlights.y));

    half3 result = diffuse + specular;
}
```
