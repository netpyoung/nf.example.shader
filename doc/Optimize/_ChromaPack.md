# ChromaPack

- 텍스쳐 압축시 품질 손상이 일어나는데 그걸 줄이는 기법 중 하나
- <https://en.wikipedia.org/wiki/Chroma_subsampling>
- Y'CbCr를 이용한다
  - <https://github.com/keijiro/ChromaPack>
  - 변형하여 YCCA를 이용한 버전 : <https://github.com/n-yoda/unity-ycca-subsampling>

|            | size    |                                       | Bit    |
| ---------- | ------- | ------------------------------------- | ------ |
| 원본       | 256x256 | rgba 256x256                          | ARGB32 |
| ChromaPack | 384x256 | Y' 256x256  / Cr 128x128 / Cb 128x128 | Alpha8 |

![ChromaPack.png](../res/ChromaPack.png)

- 이미지 압축시 품질 손실을 막기위해 고안
  - 예로 유니티 내장 PVRTC 변환툴로 변환하면 텍스쳐 압축시 품질저하가 일어남(일러스트같은경우 문제가됨)
  - 품질저하를 줄인 상용 이미지 편집기가 있기도 함
  - ASTC가 나온이상, 이게 필요할까? 라는 의문점이 있음
- 원본이미지를 Y'CbCr로 바뀌어 하나의 채널만을 이용하여 저장. (이미지 사이즈가 늘어나기에 POT이미지인 경우 NPOT로 바뀌게 됨)
- 알파있는 것은 Y'의 8비트중 1비트를 이용하여 처리

## Ref

- <https://lab.uwa4d.com/lab/5bea3d7572745c25a8852f46>
  - <https://blog.uwa4d.com/archives/TechSharing_186.html>
- <https://techblog.kayac.com/texture-compression-in-yuv>
  - <https://github.com/hiryma/UnitySamples/tree/master/Yuv>
- [2020 - Dev Weeks: 성능 프로파일링과 최적화](https://www.youtube.com/watch?v=4kVffWfmJ60&t=4870s)
