# PostProcessUberShader

- 여러패스가 아닌 하나의 패스로 관리
  - 여러번 전채화면이 Blit되는 것을 방지
  - 공통되게 사용되는 정보(예: 밝기)등 이용

``` hlsl
#pragma multi_compile_local_fragment _ _KEY_A
```

``` cs
material.EnableKeyword("_KEY_A");
material.DisableKeyword("_KEY_A");
```

## Ref

- <https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.universal/Shaders/PostProcessing/UberPost.shader>