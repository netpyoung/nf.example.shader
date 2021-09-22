# BRDF

- Bidirectional reflectance distribution function

## BRDF Texture

- BRDF Fake라고도 함.

![./res/BRDF_dir.jpg](./res/BRDF_dir.jpg)

``` hlsl
half u = dot(L, N) * 0.5 + 0.5;
half v = dot(V, N);

half3 brdfTex = SAMPLE_TEXTURE2D(_BrdfTex, sampler_BrdfTex, half2(u, v)).rgb;
```

## TODO - Ambient BRDF

- Gotanda 2010

|   |           |
|---|-----------|
| x | dot(V, N) |
| y | Shininess |

## TODO - Environment IBL Map

- Schlick's approximation // fresnel
- Lazarov 2013

|   |                    |
|---|--------------------|
| x | dot(V, N) // cosθv |
| y | Roughness          |

## DFG LUT

| DFG |              |
|-----|--------------|
| D   | Distrubution |
| F   | Fresnel      |
| G   | Geometry     |

## Ref

- SIGGRAH 2013 Real Shading in Unreal Engine 4
  - <https://lifeisforu.tistory.com/348>
- <https://learnopengl.com/PBR/IBL/Specular-IBL>
- [SIGGRAH2019 - A Journey Through Implementing Multiscattering BRDFs and Area Lights](https://advances.realtimerendering.com/s2019/A%20Journey%20Through%20Implementing%20Multiscattering%20BRDFs%20and%20Area%20Lights.pptx)
- <https://teodutra.com/unity/shaders/cook-torrance/lookup-texture/2019/03/28/Lookup-The-Cook-Torrance/>
- [SIGGRAH2017 - Physically-Based Materials: Where Are We?](http://openproblems.realtimerendering.com/s2017/index.html)
