# nf.example.shader

- [github: nf.example.shader](https://github.com/netpyoung/nf.example.shader)
  - [collections](https://github.com/netpyoung/nf.example.shader/tree/master/nf.example.shader/Assets)
  - [SRP](https://github.com/netpyoung/nf.example.shader/tree/master/nf.example.srp/Assets)

- [ShaderArt 관련](https://github.com/netpyoung/unity.shader.sandbox)
- [ComputeShader 관련](https://github.com/netpyoung/nf.example.computeshader)

{% for post in site.categories['Links'] %}
<article class="archive-item">
  <h4><a href="{{ site.baseurl }}{{ post.url }}">{{post.title}}</a></h4>
</article>
{% endfor %}

## URP

- [Linear And Gamma](./unity_SRP/linear_and_gamma.md)

## Shader

- [Vector](./doc/Basic/Vector.md)
- [Coordinate](./doc/Basic/Coordinate.md)
- [Normal Mapping](./doc/Basic/NormalMap.md)

- [Lighiting Model](./doc/LightingModel.md)
- [AnisTropy Specular](./doc/HairAnisotropic.md)
- IBL(Image-based Lighting)
  - CubeMap
  - Reflection
  - Refraction
- Depth
  - [Screen Space Decal](./doc/ScreenSpaceDecal.md)

- [Parallax Mapping](./doc/ParallaxMapping.md)


## tech

- PostEffect
- Depth Intersection
- Outline
- Dissolve
- Fresnel
- Shadow
- SSS(SubSurface Scattering)

## optimize

- Mesh Combine
- [Texture Combine](./doc/Optimize/OptimizeCombineTexture.md)
- ramp
- [better pow](./doc/Optimize/SpecularPowApproximation.md)
- BRDF Map

## RenderFeature

Sobel Filter

<div class="juxtapose" data-animate="false">
  <img src="/ImgHosting1/SRP/Sobel_before.jpg" data-label="" />
  <img src="/ImgHosting1/SRP/Sobel_after.jpg" data-label="" />
</div>

Bloom(with DualFilter)

<div class="juxtapose" data-animate="false">
 <img src="/ImgHosting1/SRP/BloomDualFilter_before.jpg" data-label="" />
 <img src="/ImgHosting1/SRP/BloomDualFilter_after.jpg" data-label="" />
</div>

Light Streak

<div class="juxtapose" data-animate="false">
 <img src="/ImgHosting1/SRP/CrossFilter_before.jpg" data-label="" />
 <img src="/ImgHosting1/SRP/CrossFilter_after.jpg" data-label="" />
</div>

Screen Space Ambient Occlusion

<div class="juxtapose" data-animate="false">
 <img src="/ImgHosting1/SRP/SSAO_before.jpg" data-label="" />
 <img src="/ImgHosting1/SRP/SSAO_after.jpg" data-label="" />
</div>

<div class="juxtapose" data-animate="false">
 <img src="/ImgHosting1/SRP/SSAO_blur_before.jpg" data-label="Wihout Blur" />
 <img src="/ImgHosting1/SRP/SSAO_blur_after.jpg" data-label="With Blur" />
</div>

Screen Space Global Illumination

<div class="juxtapose" data-animate="false">
 <img src="/ImgHosting1/SRP/SSGI_before.jpg" data-label="" />
 <img src="/ImgHosting1/SRP/SSGI_after.jpg" data-label="" />
</div>

<div class="juxtapose" data-animate="false">
 <img src="/ImgHosting1/SRP/SSGI_only_before.jpg" data-label="Wihout Blur" />
 <img src="/ImgHosting1/SRP/SSGI_only_after.jpg" data-label="Raw RenderTexture" />
</div>

Light Shaft

<div class="juxtapose" data-animate="false">
 <img src="/ImgHosting1/SRP/LightShaft_before.jpg" data-label="Origin" />
 <img src="/ImgHosting1/SRP/LightShaft_after.jpg" data-label="LightShaft Without Blur" />
</div>

FXAA

<div class="juxtapose" data-animate="false">
  <img src="/ImgHosting1/SRP/FXAA_before.png" data-label="" />
  <img src="/ImgHosting1/SRP/FXAA_after.png" data-label="" />
</div>
