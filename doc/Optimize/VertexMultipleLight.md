# VertexMultipleLight

- God of war 3에서 여러 광원처리 기법
  - pixel shader가 느렸던 기기여서 vertex에서 처리

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

        OUT.Diffuse_Points += saturate(dot(N, L_attenuated)) * additionalLight.color;
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

## Ref

- [SIGGRAPH2011 - Dynamic lighting in God of War 3](https://advances.realtimerendering.com/s2011/index.html)
  - [Comments on Advances in Real Time Rendering 2011](http://www.thetenthplanet.de/archives/1337)
