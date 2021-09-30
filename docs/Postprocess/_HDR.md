# HDR

- 컴퓨터 모니터와 같은 LDR 매체에서 볼 수 있지만 HDR 이미지의 선명도와 톤 범위를 갖는 결과 이미지를 생성
- Bloom(빛발산)/Eye Adaptation(광적응)/ToneMapping/감마보정

## Bloom

1. 일정 밝기의 한계점(Threshold)을 넘는 부분을 저장
2. 블러
3. 원본이미지와 합치기

## Eye Adaptation

- 참고: [EyeAdaptation](./EyeAdaptation.md)

## ToneMapping

- 참고: [ToneMapping](./ToneMapping.md)

## 감마보정

- linear color를 마지막에 gamma적용시킴
- `pow(linearColor, 2.2);`

## RGBM과 LogLUV 

TODO

- <http://egloos.zum.com/cagetu/v/5697725>
- <https://kblog.popekim.com/2013/11/blendable-rgbm.html>

## 통합셰이더 예제

- CHROMATIC_ABERRATION 색수차 - 렌즈 무지개현상
- BLOOM(dirt w/o)
- Vignette 카메라 가장자리 어둡게 하는 효과
- ApplyColorGrading
- FlimGrain 필름 표면 미세한 입자(노이즈)
- DITHERING

## Ref

- [[Ndc12] 누구나 알기쉬운 hdr과 톤맵핑 박민근](https://www.slideshare.net/agebreak/ndc12-hdr)
- [Ndc11 이창희_hdr](https://www.slideshare.net/cagetu/ndc11-hdr)
- [HDR - 김정희, 최유표](https://www.slideshare.net/youpyo/hdr-8480350)
- [KGC2014 - 울프나이츠 엔진 프로그래밍 기록](https://www.slideshare.net/hyurichel/kgc2014-41150275)
- <https://www.ea.com/frostbite/news/high-dynamic-range-color-grading-and-display-in-frostbite>
- <https://research.activision.com/publications/archives/hdr-in-call-of-duty>
