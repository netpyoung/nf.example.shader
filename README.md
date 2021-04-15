# nf.example.shader

- 셰이더 모음집
- 자료가 파편화되어있고 기억력 부족이라 보존용으로 만듬.
- Vertex / Fragment Shader 위주
  - [ShaderArt 관련](https://github.com/netpyoung/unity.shader.sandbox)
  - [ComputeShader 관련](https://github.com/netpyoung/nf.example.computeshader)
- [스터디 자료](./doc/Lecture.md)

## URP

- [Linear And Gamma](./urp_shader/linear_and_gamma.md)
- `#include`
- URP Pass tags: LightMode
- Property attributes
- Custom Shader Editor

## Shader

- [Vector](./doc/Vector.md)
  - Transform
  - Swizzling
- Coordinate
- UV
- [Normal Mapping](./doc/NormalMap.md)
- [Parallax Mapping](./doc/ParallaxMapping.md)
- Blend
- Cull
- Stencil
- [Lighiting Model](./doc/LightingModel.md)
- [AnisTropy Specular](./doc/HairAnisotropic.md)
- IBL(Image-based Lighting)
  - CubeMap
  - Reflection
  - Refraction
- Depth
  - [Screen Space Decal](./doc/ScreenSpaceDecal.md)

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

## package and tool

## TODO

- 런타임 메쉬 제작
  - 궤적
  - 검기