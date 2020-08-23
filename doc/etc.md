## lambert
max(0, dot(N, L))

## half lambert 

## wrapped
_wrapped =0 : lambert
_wrapped =1 : half lambert

```
diffuse = max(0, (dot(N, L) + _wrapped) / (1 - _wrapped)));
```

## Toon Ramp
NPAR07_IllustrativeRenderingInTeamFortress2



## Parallax Refraction  ??
시차(視差: 관측 위치에 따른 물체의 위치나 방향의 차이)

## phong
## blinn phong
## SSS (Subsurface Scattering)

## AO(Ambient Occlusion) - https://gpgstudy.com/forum/viewtopic.php?t=22536
ambient occlusion 은 말 그대로 "주변의 빛이 얼마나 가렸느냐"를 의미하기 때문에
경계가 불분명하고 광원이 움직여도 영향을 받지 않습니다.

shadow 같은 경우에는 "광원에서 나오는 빛이 얼마나 가렸느냐"를 의미하기 때문에
경계가 분명하며 광원이 움직일때 같이 변경됩니다


## IBL
### IBL-Reflection
### IBL-Refraction
### Frenel


## BRDF(Bidirectional Reflectance Distribution Function)
- Texture
Microfacet Theory


연기 + SSS
x-ray
빗방울 바닥 / 유리 
블러드(투명)
렌즈플레어 - 빛과 렌즈 빛의문향 - https://blog.naver.com/daehuck/220789048084
강/바다
폭포
눈쌓이기
스케치효과
홀로그램
- bloom

## Rim light
림라이트효과와 반사광효과를 흉내낼 수있다.

## Dissolve
녹다, 용해되다


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

불 이글거리는 쉐이더

===============
head size
height
weight - 부피

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

====
[SSD 스크린스페이스데칼](https://www.slideshare.net/blindrendererkr/40000)

SSD이전 데칼
벽에 총알 자국
쉬움: 벽 메쉬의 폴리곤 수 늘림
복잡: 복제한 메쉬 패치에 있는 정점마다 UV좌표를 "잘" 계산.

SSD 배경
- Deferred Decals(Jan Krassnigg, 2010)
- Volume Decals (Emil Persson, 2011)

SSD 절차
1. SSD를 제외한 메쉬들을 화면에 그림
2. SSD 상자를 그림(rasterization)
3. 각 픽셀마다 장면깊이(scene depth)를 읽어옴
4. 그 깊이로부터 3D 위치를 계산함
5. 그 3D 위치가 SSD 상자 밖이면 레젝션(rejection)
6. 그렇지 않으면 데칼 텍스처를 그림

==============
GI: Global Illumination
https://en.wikipedia.org/wiki/Global_illumination - 사진


서피스에서 반사되거나 굴절되는 모든 빛을 새로운 광원으로 삼는 것을

출처: https://lifeisforu.tistory.com/374?category=567143 [그냥 그런 블로그]


이미지 IBL
https://wiki.jmonkeyengine.org/jme3/advanced/pbr_part3.html


======
미네르트 모델
``` shader
float3 NdotL = max(0.0f, dot(N, L));
float3 NdotV = max(0.0f, dot(N, V));
float3 diffuse = NdotL * pow(NdotL * NdotV, _MinnaertDarkness);
```

오렌네이어
``` shader
float3 NdotL = max(0.0f, dot(N, L));
float3 NdotV = max(0.0f, dot(N, V));
float3 VdotL = max(0.0f, dot(V, L));

float3 s = VdotL - NdotL * NdotV;
float3 t = lerp(1.0f, max(NdotL, NdotV), step(0.0f, s));

float3 A = 1.0 + _OrenNayarAlbedo * (_OrenNayarAlbedo / (_OrenNayarSigma + 0.13) + 0.5 / (_OrenNayarSigma + 0.33));
float3 B = 0.45 * _OrenNayarSigma / (_OrenNayarSigma + 0.09);

float3 diffuse = _OrenNayarAlbedo * max(0.0, NdotL) * (A + B * s / t) / 3.14159265;
```

Burley 조명 모델
https://canny708.blog.me/221551549052


- [SIGGRAPH University - Introduction to "Physically Based Shading in Theory and Practice"](https://youtu.be/j-A0mwsJRmk)

PBR
https://blog.hybrid3d.dev/2018-04-12-misunderstandings-in-pbr

`러프니스`와 `메탈릭`의 파라미터화
환경맵을 사용한 PBR 기반 `IBL(Image-Based Lighting)`

===========
그리면 코드 알려줌
http://detexify.kirelabs.org/classify.html


https://en.wikipedia.org/wiki/List_of_common_3D_test_models
Cornell Box https://en.wikipedia.org/wiki/Cornell_box
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



나무
  빌보드쉐이더
  https://www.sysnet.pe.kr/2/0/11641

케릭터
 피부
   - SSS
 머리카락?
 갑옷
   - 메탈릭
 이펙트
   - 발광
   
거울
텔레비전

parallex shader 평면 원근감
Spherical Mask - https://www.youtube.com/watch?v=Ws4ukvCgTOU
```
Shader "MinGyu/SphericalMask" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_ColorStrength ("Color Strength", Range(1,4)) = 1

		_EmissionColor ("Emission Color", Color) = (1,1,1,1)
		_EmissionTex ("Emission (RGB)", 2D) = "white" {}
		_EmissionStrength ("Emission Strength", Range(0,10)) = 1

		_Position ("World Position", Vector) = (0,0,0,0)
		_Radius ("Sphere Radius", Range(0,100)) = 0
		_Softness ("Sphere Softness", Range(0,100)) = 0	
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200

		CGPROGRAM
		#pragma surface surf Standard fullforwardshadows
		#pragma target 3.0

		sampler2D _MainTex;
		sampler2D _EmissionTex;

		struct Input {
			float2 uv_MainTex;
			float2 uv_EmissionTex;
			float3 worldPos;
		};

		fixed4 _Color, _EmissionColor;
		half _ColorStrength, _EmissionStrength;

		// Spherical Mask
		uniform float4 GLOBALmask_Position;
		uniform half GLOBALmask_Radius;
		uniform half GLOBALmask_Softness;

		void surf (Input IN, inout SurfaceOutputStandard o) {
			// Color
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			
			// Grayscale
			float grayscale = (c.r + c.g + c.b) * 0.333;
			fixed3 c_g = fixed3(grayscale, grayscale, grayscale);

			// Emission
			fixed4 e = tex2D(_EmissionTex, IN.uv_EmissionTex) * _EmissionColor * _EmissionStrength;

			half d = distance(GLOBALmask_Position, IN.worldPos);
			half sum = saturate((d - GLOBALmask_Radius) / -GLOBALmask_Softness);
			fixed4 lerpColor = lerp(fixed4(c_g,1), c * _ColorStrength, sum);
			fixed4 lerpEmission = lerp(fixed4(0,0,0,0), e, sum);
						
			o.Albedo = lerpColor.rgb;
			o.Emission = lerpEmission.rgb;
			o.Alpha = c.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}

```

tex2Dlod
https://developer.download.nvidia.com/cg/tex2Dbias.html
https://gamedevforever.com/325?category=387045


---------
텍스쳐 그리기 : https://www.youtube.com/watch?v=hySgDB3AI4o
Banded Lighting

NDF(Normal Distribution Function)
gpg3권 4.19 수작업으로 만든 셰이딩 모형으로 렌더링하기
https://www.jordanstevenstechart.com/physically-based-rendering




https://github.com/wdas/brdf - compiled - https://www.disneyanimation.com/technology/brdf.html