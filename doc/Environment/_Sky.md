# Sky

## 메쉬 형태

- Cube, HemiSphere(SkySphere), Sphere(SkyDome)
- 유니티에서는 Skybox의 메쉬를 지정할 수 있는 방법이 없다.(2021.09.23 기준)

| Shader            | Mesh   | draw        |
| ----------------- | ------ | ----------- |
| Mobile/Skybox     | Cube   | Draw(6) * 6 |
| Skybox/6 Sided    | Cube   | Draw(6) * 6 |
| Skybox/Cubemap    | Sphere | Draw(5040)  |
| Skybox/Panoramic  | Sphere | Draw(5040)  |
| Skybox/Procedural | Sphere | Draw(5040)  |

![renderdoc_skyboxmesh.png](../res/renderdoc_skyboxmesh.png)

- 유니티 Skybox 설정 : `Window > Rendering > Lighting > Environment`
  - `unity_SpecCube0`가 위에서 설정된 메테리얼로 스카이박스를 렌더링함.(`Camera > Background Type`과는 상관없음)

## 유니티 Skybox셰이더 작성시 주의점

- URP 환경이라도 Built-in(legacy)의 기본 Pass의 태그값 `"LightMode" = "ForwardBase"`로 하여야만 동작한다.

## image

- [How to Create Skies for 3D Games?](https://80.lv/articles/how-to-create-skies-for-3d-games/)

구름을 표현하기 위해 돔형태의 메쉬, 링형 매쉬, 평면 매쉬를 이용했다.

![skybox.jpg](../res/skybox.jpg)

![skybox2.jpg](../res/skybox2.jpg)

## 구성요소

- Time Of Day // TOD
- Weather
- Color Palette
- Tone of the Narrative

- 해/달/별/기타 천체
- 구름
- 낮/밤/노을


## Case Study

- [마른 하늘에 날구름 넣기](https://www.slideshare.net/ajinkim/ss-58266584)

``` hlsl
float3 _SkyColor_Top
float3 _SkyColor_Middle
float3 _SkyColor_Bottom
float3 _SkyColor_Sunset
float3 _SkyColor_Day;

float VdotUp = max(0, dot(V, float3(0, -1, 0)));
float skyAmount = pow(1.0 - VdotUp, 8.0);

float3 sunset = lerp(_SkyColor_Sunset, _SkyColor_Middle, saturate(dot(float3(0, 1, 0), _WorldSpaceLightPos0.xyz)));
float3 skyColor = lerp(sunset, _SkyColor_Bottom, skyAmount);
float3 finalSkyColor = lerp(skyColor, _SkyColor_Top, VdotUp);

float3 emessive = lerp(_SkyColor_Day, _NightColor, _WorldSpaceLightPos0.y);


// ref: [mapping texture uvs to sphere for skybox](https://gamedev.stackexchange.com/questions/189357/mapping-texture-uvs-to-sphere-for-skybox)
// ref: [Correcting projection of 360° content onto a sphere - distortion at the poles](https://gamedev.stackexchange.com/questions/148167/correcting-projection-of-360-content-onto-a-sphere-distortion-at-the-poles/148178#148178)

uv.x = (PI + atan2(positionWS.x, positionWS.z)) * INV_TWO_PI;
uv.y = uv.y * 0.5 + 0.5
```

- [ARM - The Ice Cave demo](https://developer.arm.com/documentation/102259/0100/Procedural-skybox)

``` hlsl
half3 _SunPosition;
half3 _SunColor;
half _SunDegree;  // [0.0, 1.0], corresponds to a sun of diameter of 5 degrees: cos(5 degrees) = 0.995

half4 SampleSun(in half3 viewDir, in half alpha)
{
        // 원형 해
        half sunContribution = dot(viewDir,_SunPosition);

        half sunDistanceFade = smoothstep(_SunDegree - (0.025 * alpha), 1.0, sunContribution);
        half sunOcclusionFade = clamp(0.9 - alpha, 0.0, 1.0);
        half3 sunColorResult = sunDistanceFade * sunOcclusionFade * _SunColor;
        return half4(sunColorResult, 1.0);
}
```

- ['Infinite' sky shader for Unity](https://aras-p.info/blog/2019/02/01/Infinite-sky-shader-for-Unity/)

``` hlsl
"reversed-Z projection"을 이용하지만, "infinite projection"

#if defined(UNITY_REVERSED_Z)
// when using reversed-Z, make the Z be just a tiny
// bit above 0.0
OUT.positionCS.z = 1.0e-9f;
#else
// when not using reversed-Z, make Z/W be just a tiny
// bit below 1.0
OUT.positionCS.z = o.positionCS.w - 1.0e-6f;
#endif
```

- [[TA] 테라에 사용된 렌더링 테크닉 - 임신형 (valhashi)](https://www.slideshare.net/valhashi/2011-03-gametechtadptforpdf)
| 단위   | Mesh                     | 역활                 |
| ------ | ------------------------ | -------------------- |
| 백드랍 | Sphere                   | 3색 그라데이션       |
| 천체   | Sphere                   | 태양, 별             |
| 구름   | HemiSphere 혹은 마음대로 | 구름 레이어 4장 lerp |



하늘

https://blog.daum.net/darksith/15

## Ref

- [Unity's built-in Skybox-Procedural.shader](https://github.com/TwoTailsGames/Unity-Built-in-Shaders/blob/master/DefaultResourcesExtra/Skybox-Procedural.shader)



https://notburning.tistory.com/category/?page=5
https://timcoster.com/2019/09/03/unity-shadergraph-skybox-quick-tutorial/

https://assetstore.unity.com/packages/tools/particles-effects/tenkoku-dynamic-sky-34435
https://assetstore.unity.com/packages/2d/textures-materials/sky/procedural-sky-builtin-lwrp-urp-jupiter-159992
https://assetstore.unity.com/packages/tools/particles-effects/azure-sky-dynamic-skybox-36050

https://www.e2gamedev.com/skybox

- https://www.youtube.com/watch?v=4QOcCGI6xO
- https://github.com/SebLague/Clouds
  - NoiseGenerator


[EasySky: Breakdown of a Procedural Skybox for UE4](https://80.lv/articles/easysky-breakdown-of-a-procedural-skybox-for-ue4/)

- [GDC2014  - Moving the Heavens: An Artistic and Technical Look at the Skies of The Last of Us](https://www.youtube.com/watch?v=o66p1QDH7aI)


https://simul.co/

- [Reaching for the stars - Let’s create a procedural skybox shader with Unity’s Shader Graph!](https://medium.com/@jannik_boysen/procedural-skybox-shader-137f6b0cb77c)
- [Volumetric Clouds – 体积云的做法](http://walkingfat.com/volumetric-clouds-%e4%bd%93%e7%a7%af%e4%ba%91%e7%9a%84%e5%81%9a%e6%b3%95/)
