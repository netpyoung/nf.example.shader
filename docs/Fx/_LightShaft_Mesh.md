# LightShaft_Mesh

- <https://developer.arm.com/documentation/102259/0100/Light-shafts>

``` hlsl
Cull Off
ZWrite Off
Blend One One

// Project camera position onto cross section
float3 DIR_UP             = float3(0, 1, 0);
float  dotWithYAxis       = dot(cameraPositionOS, DIR_UP);
float3 projOnCrossSection = normalize(cameraPositionOS - (DIR_UP * dotWithYAxis));

// Dot product to fade the geometry at the edge of the cross section
float dotProd           = abs(dot(projOnCrossSection, input.normal));
output.overallIntensity = pow(dotProd, _FadingEdgePower) * _CurrLightShaftIntensity;
```

## Ref

- <https://assetstore.unity.com/packages/vfx/shaders/volumetric-light-beam-99888>
- <https://assetstore.unity.com/packages/tools/particles-effects/as-lightshafts-2-13196>
