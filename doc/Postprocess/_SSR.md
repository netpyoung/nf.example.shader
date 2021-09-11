# SSR / Screen Space Reflection

TODO 작성중

해당 픽셀의 노멀과 뎁스버퍼를 사용하여 리플렉션 벡터를 구합니다. 

리플렉션 벡터는 계속 직진하여 스크린 스페이스 밖으로 나가거나 어떤 오브젝트와 부딫히게 될 것입니다.

리플렉션 벡터를 따라서 Ray-Marching합니다.
Ray-Marching은 ray tracing의 진보된 방법으로써 어떤 오브젝트와 충돌하는 지점만 계산하는 것이 아니라
공간을 지나면서 변화되었거나 특정 값을 기준으로 step 화 시켜서 나누어 계산하는걸 뜻합니다.

정보가 없는 반사부분을 자연스럽게 fade out시키는 기법이 쓰입니다.

jitter 흐뜨려트림

## Ref

- <https://www.slideshare.net/xtozero/screen-space-reflection>
- <https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.postprocessing/PostProcessing/Shaders/Builtins/ScreenSpaceReflections.hlsl>
- <https://github.com/kode80/kode80SSR>
- [Unity で Screen Space Reflection の実装をしてみた](https://tips.hecomi.com/entry/2016/04/04/022550)
  - <https://github.com/hecomi/UnityScreenSpaceReflection>
- [GDC2016 - Low Complexity, High Fidelity: The Rendering of INSIDE](https://youtu.be/RdN06E6Xn9E?t=2243)
- [GDC2016 - Temporal Reprojection Anti-Aliasing in INSIDE](https://www.youtube.com/watch?v=2XXS5UyNjjU)
  - <https://github.com/playdeadgames/temporal>
- [GPU Pro 6: Advanced Rendering Techniques - II: RENDERING - 1.2.3 Screen-Space Reflections](https://books.google.co.kr/books?id=30ZOCgAAQBAJ&pg=PA65&lpg=PA65#v=onepage&q&f=false)
- Approximating ray traced reflections using screen-space data by MATTIAS JOHNSSON
