# Fog

``` hlsl
// Fog
#pragma multi_compile_fog

OUT.fogCoord = ComputeFogFactor(IN.positionOS.z); // float

color = MixFog(color, IN.fogCoord);
```

``` txt
Windows> Rendering> Lighting

Other Settings> Fog
```
