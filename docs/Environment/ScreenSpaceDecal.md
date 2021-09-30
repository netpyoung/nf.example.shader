# Screen Space Decal

- Deferred Decals(Jan Krassnigg, 2010)
- Volume Decals (Emil Persson, 2011)
- SSD : [SIGGRAPH2012 - ScreenSpaceDecal](https://www.slideshare.net/blindrenderer/screen-space-decals-in-warhammer-40000-space-marine-14699854)
- 큐브를 프로젝터처럼 이용, 화면에 데칼을 그린다.
- 뎁스로부터 포지션을 다시 구축하는 것이므로 `Reconstructing position from depth`라고도 한다.

1. SSD를 제외한 메쉬들을 화면에 그림
2. SSD 상자를 그림(rasterization)
3. 각 픽셀마다 장면깊이(scene depth)를 읽어옴
4. 그 깊이로부터 3D 위치를 계산함
5. 그 3D 위치가 SSD 상자 밖이면 레젝션(rejection)
6. 그렇지 않으면 데칼 텍스처를 그림

## ver1. URP

``` hlsl
// NDC에서 depth를 이용 역산하여 데칼 위치를 구하는법.

// vert:
OUT.positionNDC = vertexPositionInput.positionNDC;

// frag:
// ============== 1. 씬뎁스 구하기
half2 uv_Screen = IN.positionNDC.xy / IN.positionNDC.w;
half sceneRawDepth = SampleSceneDepth(uv_Screen);
half sceneEyeDepth = LinearEyeDepth(sceneRawDepth, _ZBufferParams);

// ============== 2. 뎁스로부터 3D위치를 구하기
// positionNDC: [-1, 1]
float2 positionNDC = uv_Screen * 2.0 - 1.0;
half4 positionVS_decal;
positionVS_decal.x = (positionNDC.x * sceneEyeDepth) / unity_CameraProjection._11;
positionVS_decal.y = (positionNDC.y * sceneEyeDepth) / unity_CameraProjection._22;
positionVS_decal.z = -sceneEyeDepth;
positionVS_decal.w = 1;

half4x4 I_MV = mul(UNITY_MATRIX_I_M, UNITY_MATRIX_I_V);
// positionOS_decal: [-0.5, 0.5] // clip 으로 잘려질것이기에 
half4 positionOS_decal = mul(I_MV, positionVS_decal);

// ============== 3. SSD상자 밖이면 그리지않기
clip(0.5 - abs(positionOS_decal.xyz));

// ============== 4. 데칼 그리기
// uv_decal: [0, 1]
half2 uv_decal = positionOS_decal.xz + 0.5;
half2 uv_MainTex = TRANSFORM_TEX(uv_decal, _MainTex);
half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv_MainTex);
```

## ver2. URP

- [Depth](./Basic/Depth.md)에선 WorldSpace상 좌표를 이용해서 Depth로부터 위치를 구했는데, 최적화를 위해 Object Space상에서 구함(한눈에 봐서는 어색하지만 따라가다보면 말이 되긴 한다)

``` hlsl
// 오브젝트 공간의 viewRay를 구하고 depth에 맞추어 데칼 위치를 구하는법.

// vert:
float4x4 I_MV = mul(UNITY_MATRIX_I_M, UNITY_MATRIX_I_V);
OUT.positionOS_camera = mul(I_MV, float4(0, 0, 0, 1)).xyz;

OUT.positionOSw_viewRay.xyz = mul((float3x3)I_MV, -vertexPositionInput.positionVS);
OUT.positionOSw_viewRay.w = vertexPositionInput.positionVS.z;

// frag:
// ============== 1. 씬뎁스 구하기
half2 uv_Screen = IN.positionNDC.xy / IN.positionNDC.w;
half sceneRawDepth = SampleSceneDepth(uv_Screen);
half sceneEyeDepth = LinearEyeDepth(sceneRawDepth, _ZBufferParams);

// ============== 2. 뎁스로부터 3D위치를 구하기
// positionOS_decal: [-0.5, 0.5] // clip 으로 잘려질것이기에
half3 positionOS_decal = IN.positionOS_camera + IN.positionOSw_viewRay.xyz / IN.positionOSw_viewRay.w * sceneEyeDepth;

// ============== 3. SSD상자 밖이면 그리지않기
clip(0.5 - abs(positionOS_decal.xyz));

// ============== 4. 데칼 그리기
// uv_decal: [0, 1]
half2 uv_decal = positionOS_decal.xz + 0.5;
half2 uv_MainTex = TRANSFORM_TEX(uv_decal, _MainTex);
half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv_MainTex);
```

## ver. Pope

1. 알파블렌딩
   - Blend Factor
2. 움직이는 물체들
   - 움직이면 데칼 적용안함(Stencil)
3. 옆면이 늘어나요.... ㅜ.ㅠ
   - 투영방향 Gbuffer의 법선방향의 각도이용 리젝션.
   - NormalThreashold
     - 60도(적정값)
     - 180도(리젝션안함)
4. 짤린(clipped) 데칼
   - 데칼상자범위가 카메라를 뚷어버리면, 뒷면을 그림(깊이 데스트 방향을 뒤집어서)
   - 회피책
     - 엄청 얇게
     - 엄청 두껍게(성능 떨어짐)

``` hlsl
// 3. 옆면이 늘어나요.... ㅜ.ㅠ

// 정점 셰이더에서 데칼 상자의 방위를 구함:
output.Orientation = normalize(WorldView[1].xyz);

gNormalThreashold == cos(각도)

// 픽셀 셰이더에서 GBuffer 법선을 읽어와 리젝션 테스트
float3 normal = DecodeGbufferNormal(tex2D(GNormalMap, depth_uv));
clip(dot(normal, orientation) - gNormalThreshold);
```

## fadeout

- [http://ttmayrin.tistory.com/37](https://web.archive.org/web/20170508024615/http://ttmayrin.tistory.com/37)

수직인 지형에서의 경계면이 잘리는 거 fadeout

``` hlsl
// 유니티는 Y가 높이이기에
// #define HALF_Y 0.25f
// OutColor *= (1.f - max((positionOS_decal.y - HALF_Y) / HALF_Y, 0.f));
OutColor *= (1.f - max(4 * positionOS_decal.y - 1, 0.f));
```

## 컨택트 섀도(Contact Shadow)

- [전형규, 가성비 좋은 렌더링 테크닉 10선, NDC2012](https://www.slideshare.net/devcatpublications/10ndc2012)

``` hlsl
float4 ContactShadowPSMain(PSInput input) : COLOR
{
  input.screenTC.xyz /= input.screenTC.w;

  float depthSample = tex2D(DepthSampler, input.screenTC.xy).x;
  float sceneDepth = GetClipDistance(depthSample);
  float3 scenePos = FromScreenToView(input.screenTC.xy, sceneDepth);

  float shadow = length(scenePos - input.origin) / (input.attributes.x + 0.001f);
  shadow = pow(saturate(1 - shadow), 2);

  const float radiusInMeter = input.attributes.x;
  float aoIntensity = saturate(4.0f - 2.5 * radiusInMeter);

  shadow *= 0.7f * input.attributes.y;

  return float4(shadow, 0.0f, shadow * aoIntensity, 0);
}
```

## Ref

- [KGC2012 - 스크린 스페이스 데칼에 대해 자세히 알아보자(워햄머 40,000: 스페이스 마린)](https://www.slideshare.net/blindrendererkr/40000)
  - [KGC 2011](https://www.slideshare.net/blindrenderer/rendering-tech-of-space-marinekgc-2011)
- [GDC2016 - Low Complexity, High Fidelity: The Rendering of INSIDE](https://www.youtube.com/watch?v=RdN06E6Xn9E&t=2153s)
- [GDC2012 - Effects Techniques Used in Uncharted 3: Drake's Deception](https://ubm-twvideo01.s3.amazonaws.com/o1/vault/gdc2012/slides/Programming%20Track/Robin_Marshall_EffectsTechniquesUsed.pdf)
- <https://github.com/ColinLeung-NiloCat/UnityURPUnlitScreenSpaceDecalShader>
  - <https://assetstore.unity.com/packages/vfx/shaders/lux-urp-essentials-150355>
- <https://blog.theknightsofunity.com/make-it-snow-fast-screen-space-snow-shader/>
- <https://samdriver.xyz/article/decal-render-intro>
- <http://www.ozone3d.net/tutorials/glsl_texturing_p08.php#part_8>
  - <https://diehard98.tistory.com/entry/Projective-Texture-Mapping-with-OpenGL-GLSL>
- <https://blog.csdn.net/puppet_master/article/details/84310361>
- <https://mynameismjp.wordpress.com/2009/03/10/reconstructing-position-from-depth/>
