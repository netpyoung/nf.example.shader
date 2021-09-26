# Optimize tip

## from [Optimizing unity games (Google IO 2014)](https://www.slideshare.net/AlexanderDolbilov/google-i-o-2014)

- Shader.SetGlobalVector
- OnWillRenderObject(오브젝트가 보일때만), propertyID(string보다 빠름)

``` cs
void OnWillRenderObject()
{
    material.SetMatrix(propertyID, matrix);
}
```

## Tangent Space 라이트 계산

- 월드 스페이스에서 라이트 계산값과 탄젠트 스페이스에서 라이트 계산값과 동일.
- vertex함수에서 tangent space V, L을 구하고 fragment함수에 넘겨줌.
  - 월드 스페이스로 변환 후 계산하는 작업을 단축 할 수 있음

## 데미지폰트

- 셰이더로 한꺼번에 출력
- <https://blog.naver.com/jinwish/221577786406>

## Chroma subsampling

- 텍스쳐 압축시 품질 손상이 일어나는데 그걸 줄이는 기법 중 하나
- <https://en.wikipedia.org/wiki/Chroma_subsampling>
- <https://github.com/keijiro/ChromaPack>
- YCbCr

## NPOT 지원안하는 텍스쳐 포맷

- NPOT지원안하는 ETC/PVRTC같은경우 POT로 자르고 셰이더로 붙여주는걸 작성해서 최적화
  - <https://blog.naver.com/jinwish/221576705990>

## GGX 공식 간략화

- Optimizing PBR for Mobile
  - [pdf](https://community.arm.com/cfs-file/__key/communityserver-blogs-components-weblogfiles/00-00-00-20-66/siggraph2015_2D00_mmg_2D00_renaldas_2D00_slides.pdf), [note](https://community.arm.com/cfs-file/__key/communityserver-blogs-components-weblogfiles/00-00-00-20-66/siggraph2015_2D00_mmg_2D00_renaldas_2D00_notes.pdf)
