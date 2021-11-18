
## BRDF(Bidirectional Reflectance Distribution Function)
- Texture
Microfacet Theory


블러드(투명)
렌즈플레어 - 빛과 렌즈 빛의문향 - https://blog.naver.com/daehuck/220789048084



Oren-Nayar

Harahan-Krueger
D : Trowbridge-Reitz/GGX normal Distribution function.
F : Fresnel term Schlick’s approximation
G : Schlick-GGX approximation
Geometry shadowing term G. Defines the shadowing from the micro facets




c++17
N4230: Nested namespace definition
http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2014/n4230.html



Disney BRDF - 주먹왕 랄프


=======
- Color Masking
- UV Animation

=======
infinite-3d-head-scan-released

????
스펙큘러반사는 Kelemen / Szirmay - Kalos Model
=====


=========
PBS
- Microfacet BRDF
  - 표면 Specular
  - 표면 Fresnel
  - 미세표면 Shadowing과 Masking
- IBL(Image Based Lighting)
  - 난반사 시뮬레이션
  - 표면 거칠기에 따라 변형되는 주변광의 모양
- 에너지 보존 법칙

PBS하려면 지원해야할것.
-- Gamma-Correct Rendering
-- High Dynamic Range Rendering
-- Tone mapping

==============
이미지 IBL
https://wiki.jmonkeyengine.org/jme3/advanced/pbr_part3.html



Burley 조명 모델
https://canny708.blog.me/221551549052


- [SIGGRAPH University - Introduction to "Physically Based Shading in Theory and Practice"](https://youtu.be/j-A0mwsJRmk)

PBR
https://blog.hybrid3d.dev/2018-04-12-misunderstandings-in-pbr

`러프니스`와 `메탈릭`의 파라미터화
환경맵을 사용한 PBR 기반 `IBL(Image-Based Lighting)`

===========


- [Cornell Box](https://en.wikipedia.org/wiki/Cornell_box)
Sponza - Frank Meinl

=====
https://blog.hybrid3d.dev/2019-11-15-raytracing-pathtracing-denoising
레이트레이싱과 패스 트레이싱
 트레이싱이 좀 더 오래 걸리고 정확한 기법이다. 가령 일반적인 레이트레이싱 알고리즘에서는 픽셀당 광선을 하나씩 쏜다. 하나씩 쏜 후 거울 등을 표현하기 위해 재귀적으로 두 세번 더 트레이싱한다. 일반적으로는 여기까지가 일반적인 레이트레이싱 알고리즘이다.

패스 트레이싱은 쉽게 말하면 레이트레이싱을 이용해서 GI를 표현하는 것이다. 스페큘러와 디퓨즈 모두 계산을 하는 것이고 더 정확히 말하면 레이트레이싱을 이용해서 렌더링 공식(rendering equation)을 계산한다고 보면 된다. 주목할만한 특징은 패스 트레이싱에서는 직접 조명을 따로 계산하지 않아도 된다는 것이다.


[Disney's Practical Guide to Path Tracing](https://www.youtube.com/watch?v=frLwRLS_ZR0)


Spherical Harmonic Lighting using OpenGL
SH diffuse

디노이저

SSR - Screen Space Reflection
- GPU Pro 6: Advanced Rendering Techniques

=====
각도구하기
https://www.sysnet.pe.kr/Default.aspx?mode=2&sub=0&pageno=0&detail=1&wid=11636


dot을 이용 cos 각도값으로 비교하면 성능향상 가능성.



---------
텍스쳐 그리기 : https://www.youtube.com/watch?v=hySgDB3AI4o
Banded Lighting

NDF(Normal Distribution Function)
gpg3권 4.18 픽셀 당 조명 계산을 위한 참조 테이블로서의 텍스처
gpg3권 4.19 수작업으로 만든 셰이딩 모형으로 렌더링하기
