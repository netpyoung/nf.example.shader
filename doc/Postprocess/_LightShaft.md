# LightShaft

- <https://en.wikipedia.org/wiki/Sunbeam#Crepuscular_rays>
- aka. Sun beam / Sun Shafts/ Crepuscular Ray / God Ray
- Shaft : 한 줄기 광선, 전광


- Shadow Volume Algorithm (Modified) [ MAX 1986 ]
- Slice-based volume-rendering technique [ Dobashi & Nishta & Yamamoto 2002 ]
- Hardware Shadow Map [ Mitchell 2004 ]
- Polygonal Volume [ James 2003 Based On Radomir Mech 2001]
- Volumetric Light Scattering [ Hoffman & Preetham 2003 ]

## 예

- Crytek
  - depth 마스크를 Radial blur를 먹여서 구현함
  - blurVector = positionWS_Sun - currPixelPositionWS;

## Ref

- [GDC2008 - Crysis Next-Gen Effects](https://www.slideshare.net/TiagoAlexSousa/crysis-nextgen-effects-gdc-2008)
- <https://developer.arm.com/documentation/102259/0100/Light-shafts>
- <https://developer.nvidia.com/gpugems/gpugems3/part-ii-light-and-shadows/chapter-13-volumetric-light-scattering-post-process>
- <https://github.com/togucchi/urp-postprocessing-examples>
- <https://blog.naver.com/sorkelf/40152690614>
- <http://maverickproj.web.fc2.com/pg65.html>
