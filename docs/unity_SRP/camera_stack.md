
- Base Camera(1) : Overlay Cameras(N)
  - Camera Component > RenderType: Base
    - Stack 섹션에 Overlay카메라 추가
  - Camera Component > RenderType: Overlay

overlay 카메라에 후처리를 넣기 어려움
커스텀 스택을 구현 렌더 텍스처로 출력후 합성
https://forum.unity.com/threads/post-processing-with-multiple-cameras-is-currently-very-problematic.1028533/page-2#post-7628767
https://portal.productboard.com/unity/1-unity-platform-rendering-visual-effects/c/2149-post-processing-alpha-preservation-setting
https://github.com/Warwlock/PULSE
https://forum.unity.com/threads/post-processing-with-multiple-cameras-is-currently-very-problematic.1028533/