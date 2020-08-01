tags: outline , 아웃라인

vertex stencilmask matcap fresnel

## 2-pass

``` shader
Pass
{
    Name "Outline"
    Cull Front
}

Pass
{
    Name "Front"

    Tags
    {
        "LightMode" = "UniversalForward"
    }
    Cull Back
}

```

### Scale확장

- 1pass 외곽선 Model - 원래 Model확장
- 2pass 원래 Model

모델이 복잡하면 아웃라인이 어긋나게됨.

``` hlsl
float4 Scale(float4 vertexPosition, float3 s)
{
    float4x4 m;
    m[0][0] = 1.0 + s.x; m[0][1] = 0.0;       m[0][2] = 0.0;       m[0][3] = 0.0;
    m[1][0] = 0.0;       m[1][1] = 1.0 + s.y; m[1][2] = 0.0;       m[1][3] = 0.0;
    m[2][0] = 0.0;       m[2][1] = 0.0;       m[2][2] = 1.0 + s.z; m[2][3] = 0.0;
    m[3][0] = 0.0;       m[3][1] = 0.0;       m[3][2] = 0.0;       m[3][3] = 1.0;
    return mul(m, vertexPosition);
}

o.vertexHCS = TransformObjectToHClip(Scale(v.vertexOS, _OutlineScale).xyz);
```

### normal 확장

- 비용쌈
- 모서리 안이어짐 (구형에 적합)

``` hlsl
float3 worldNormalLength = length(TransformObjectToWorldNormal(v.normal));
float3 outlineOffset = _OutlineThickness * worldNormalLength * v.normal;
v.vertex.xyz += outlineOffset;
o.vertex = TransformObjectToHClip(v.vertex.xyz);
```

폴리곤 오프셋 = thickness x dist x fovx / width 


[외곽선 렌더링 구현에 관한 허접한 정리](https://gamedevforever.com/18)
https://gpgstudy.com/forum/viewtopic.php?t=5869


### normal 확장 with smooth

  - 1. 모델설정변경방법.. `.fbx -> Model, Normal & Tangent Normals -> Normals:Calculate, Smoothing Angel:180`
  - 2. smooth노멀 미리 굽는 방법
    - <https://blog.naver.com/mnpshino/221495979665>

## 후처리

- silhouette outline
https://roystan.net/articles/outline-shader.html
https://docs.unity3d.com/Packages/com.unity.render-pipelines.universal@9.0/api/UnityEngine.Rendering.Universal.ScriptableRendererFeature.html
https://alexanderameye.github.io/outlineshader.html

- <https://docs.unity3d.com/Manual/SL-CameraDepthTexture.html>

`_CameraDepthTexture`
`_LastCameraDepthTexture`

sampler2D _CameraGBufferTexture0; // rgb: diffuse,  a: occlusion
sampler2D _CameraGBufferTexture1; // rgb: specular, a: smoothness
sampler2D _CameraGBufferTexture2; // rgb: normal,   a: unused
sampler2D _CameraGBufferTexture3; // rgb: emission, a: unused
sampler2D _CameraDepthTexture


`_CameraColorTexture`
`_CameraDepthNormalsTexture`



UniversalRenderPipelineAsset.asset > General > Depth Texture


일단 먼저 정상적으로 씬 전체를 렌더링합니다.
그 후, 외곽선이 필요한 오브젝트를 단색으로 그립니다. (빨간색 외곽선이라 가정하겠습니다)이때 깊이 버퍼는 살아있어야 하고  오퍼레이션은  equal로 설정합니다. 그렇게 되면 오브젝트가 실제로 그려진 영역만 단색으로 마스킹 처리가 됩니다.
그 후 마스킹 버퍼에서 빨간색을 외곽선 두께로 사용 할 만큼 확장합니다. (이 버퍼는 빨간색이 아닌 색으로 초기화 되어 있어야 하겠지요)
그리고서는 그 확장한 마스킹 버퍼를 오브젝트 원래 영역을 제외하고 화면에 덮어씌우면 됩니다.
pass 3에서 원래 영역 제외는 어떻게 하면 될까요? 그것도 어렵지 않아요~ 
스텐실을 사용할 수도 있고, 알파 채널을 이용할 수도 있는데, 알파 채널을 이용하는 것으로 말씀을 드리겠습니다. 
먼저, 위의 pass 1에서 마스킹 버퍼에 오브젝트를 그릴 시 알파 채널에 특정한 값을 새깁니다. 물론 블렌딩은 끈 상태로요.
확장 처리를 할 시 RGB 채널의 값만 확장하고 A 채널의 값은 그대로 둡니다.
그리고서 화면에 씌울 시 A 채널의 값을 확인해서 씌울지 안 씌울지를 선택을 하면 되는 것이죠.



## 외곽선 검출 필터

https://en.wikipedia.org/wiki/Sobel_operator
  
  https://docs.unity3d.com/Packages/com.unity.render-pipelines.universal@7.2/manual/rendering-to-a-render-texture.html

  https://www.ronja-tutorials.com/2020/07/23/sprite-outlines.html
  
  https://medium.com/@bgolus/the-quest-for-very-wide-outlines-ba82ed442cd9

https://www.codinblack.com/outline-effect-using-shader-graph-in-unity3d/


- BRDF이용



- https://assetstore.unity.com/packages/tools/particles-effects/highlighting-system-41508#content
- PixelPerfectOutline
- https://www.videopoetics.com/tutorials/pixel-perfect-outline-shaders-unity/

https://github.com/unity3d-jp/UnityChanToonShaderVer2_Project/blob/release/urp/2.2/Runtime/Shaders/UniversalToonOutline.hlsl



1. 캐릭터 등의 어차피 SRP Batcher가 작동하지 않는 오브젝트에서는 코드에 아웃라인 패스를 삽입하여 머티리얼별로 제어를 해 주도록 하자
2. 배경 등의 오브젝트에 외곽선을 그릴일이 있고 멀티-서브 머티리얼을 사용하지 않는다면 강제로 두번째 머티리얼을 사용해 주자.
3. 배경 등의 오브젝트에 외곽선을 그릴일이 있고 멀티-서브 머티리얼을 사용한다면 렌더오브젝트 - 오버라이드 머티리얼을 사용하자.
​[출처] UPR 셰이더 코딩 튜토리얼 : 제 2편 - SRP Batcher와 MultiPass Outline|작성자 Madumpa