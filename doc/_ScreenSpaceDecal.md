# Screen Space Decal / SSD

큐브를 프로젝터처럼 이용, 화면에 데칼을 그린다.

1. 씬뎁스 구하기
2. 뎁스로부터 3D위치를 구하기
3. SSD상자 밖이면 그리지않기
4. 데칼 그리기


## ver. Pope

``` hlsl
// ver. Pope

// ============== 1. 씬뎁스 구하기
float2 screenPosition = clipPosition.xy / clipPosition.w;
float2 depth_uv = screenPosition * float2(0.5f, -0.5f) + float2(0.5f, 0.5f);
depth_uv += ScreenDimension.zw; // Half-pixel Offset Basically

float sceneDepth = tex2D(DepthMap, depth_uv).r;

// ============== 2. 뎁스로부터 3D위치를 구하기
float4 scenePosView = float4((clipPosition.xy * sceneDepth) / (Deproject.xy * clipPosition.w), -depth, 1);

// Deproject.X = ProjectionMatrix.M11;
// Deproject.Y = ProjectionMatrix.M22;

position = mul(scenePosView, InvWorldView);

// ============== 3. SSD상자 밖이면 그리지않기
clip(0.5 - abs(position.xyz));

// ============== 4. 데칼 그리기
float2 uv = position.xz;
uv += 0.5f
```

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

## ver. URP

``` hlsl
// ver. URP

// ============== 1. 씬뎁스 구하기
VertexPositionInputs vertexInputs = GetVertexPositionInputs(positionOS.xyz);

half4 positionNDC = vertexInputs.positionNDC;
half2 uv_Screen = IN.positionNDC.xy / IN.positionNDC.w;
half sceneDepth = SampleSceneDepth(uv_Screen);

// ============== 2. 뎁스로부터 3D위치를 구하기
// for Perspective
half sceneDepthVS = LinearEyeDepth(sceneDepth, _ZBufferParams);

half4 decalPositionVS;
decalPositionVS.x = (positionCS.x * sceneDepth) / (UNITY_MATRIX_P._11 * positionCS.w);
decalPositionVS.y = (positionCS.y * sceneDepth) / (UNITY_MATRIX_P._22 * positionCS.w);
decalPositionVS.z = -sceneDepthVS;
decalPositionVS.w = 1;

// mul(decalPositionVS, invViewWorld);
half4 decalPositionOS = mul(UNITY_MATRIX_IT_MV, decalPositionVS);


// 희안하네
half sceneDepthVS = LinearEyeDepth(sceneDepth, _ZBufferParams);
{ // vert
  float4x4 I_MV = mul(UNITY_MATRIX_I_M, UNITY_MATRIX_I_V);
  OUT.viewRayOS.xyz = mul((float3x3)I_MV, -vertexPositionInput.positionVS);
  OUT.viewRayOS.w = vertexPositionInput.positionVS.z;
} // vert
half3 decalPositionOS = viewRayOS.xyz / viewRayOS.w * sceneDepthVS;


// for Orthographic
float sceneDepthVS = lerp(_ProjectionParams.y, _ProjectionParams.z, sceneDepth); // lerp(near,far, [0,1] linear depth) 
half4 decalPositionVS = half4(positionCS.xy * sceneDepth) / (Deproject.xy * positionCS.w), -sceneDepthVS, 1);

// Deproject.X = ProjectionMatrix.M11;
// Deproject.Y = ProjectionMatrix.M22;

decalPositionOS = mul(decalPositionVS, I_MV);

// ============== 3. SSD상자 밖이면 그리지않기

clip(0.5 - abs(decalPositionOS.xyz));


// ============== 4. 데칼 그리기
half2 uv_DecalSpace = decalPositionOS.xy + 0.5;
half2 uv_MainTex = TRANSFORM_TEX(uv_DecalSpace, _MainTex);
half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv_MainTex);

|        |                                                              |
|--------|--------------------------------------------------------------|
| 근평면 | 카메라와 수직하며 제일 가까운 곳의 시야 범위를 나타내는 평면 |
| 원평면 | 카메라와 수직하며 제일 먼 곳의 시야 범위를 나타내는 평면     |
| 좌평면 | 카메라의 좌측 시야 범위를 나타내는 평면                      |
| 우평면 | 카메라의 우측 시야 범위를 나타내는 평면                      |
| 상평면 | 카메라의 상단 시야 범위를 나타내는 평면                      |
| 하평면 | 카메라의 하단 시야 범위를 나타내는 평면                      |

```

## 종합

``` hlsl
Shader "ScreenSpaceDecal"
{
    Properties
    {
        [Header(Blending)] // https://docs.unity3d.com/ScriptReference/Rendering.BlendMode.html
        [Enum(UnityEngine.Rendering.BlendMode)]
        _SrcBlend("_SrcBlend (default = SrcAlpha)", Float)          = 5  // SrcAlpha         == 5
        [Enum(UnityEngine.Rendering.BlendMode)]
        _DstBlend("_DstBlend (default = OneMinusSrcAlpha)", Float)  = 10 // OneMinusSrcAlpha == 10


        // TODO 잘 모르겠다 스텐실은..
        [Header(Stencil Masking)] // https://docs.unity3d.com/ScriptReference/Rendering.CompareFunction.html
        _StencilRef("_StencilRef", Float) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)]_StencilComp("_StencilComp (default = Disable) _____Set to NotEqual if you want to mask by specific _StencilRef value, else set to Disable", Float) = 0 //0 = disable
    }

    SubShader
    {
        // To avoid render order problems, Queue must >= 2501, which enters the transparent queue, 
        // in transparent queue Unity will always draw from back to front
        // https://github.com/ColinLeung-NiloCat/UnityURPUnlitScreenSpaceDecalShader/issues/6#issuecomment-615940985

        // https://docs.unity3d.com/Manual/SL-SubShaderTags.html
        // Queues up to 2500 (“Geometry+500”) are consided “opaque” and optimize the drawing order of the objects for best performance. 
        // Higher rendering queues are considered for “transparent objects” and sort objects by distance, 
        // starting rendering from the furthest ones and ending with the closest ones. 
        // Skyboxes are drawn in between all opaque and all transparent objects.
        // "Queue" = "Transparent-499" mean "Queue" = "2501", which is almost equals "draw right before any transparent objects"
        Tags
        {
            "RenderPipeline" = "UniversalRenderPipeline"
            "Queue" = "Transparent-499"
            "RenderType" = "Overlay"
            "DisableBatching" = "True"
        }
        Pass
        {
            Name "SCREEN_SPACE_DECAL"

            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Stencil
            {
                Ref  // TODO
                Comp // TODO
            }
            Cull Back
            ZWrite off
            Blend[_SrcBlend][_DstBlend]
            HLSLPROGRAM


// PipelineAsset.asset > General > Depth Texture> Check
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            
#if _ProjectionAngleDiscardEnable
// 직접계산
float3 decalSpaceHardNormal = normalize(
  cross(ddx(decalSpaceScenePos), ddy(decalSpaceScenePos))
);
// 혹은 노말맵으로 계산TODO
clip(decalSpaceHardNormal.z - _ProjectionAngleDiscardThreshold);
#else

#endif

            ENDHLSL
        }
    }
}
```















``` hlsl



#if _ProjectionAngleDiscardEnable
// also discard "scene normal not facing decal projector direction" pixels
float3 decalSpaceHardNormal = normalize(cross(ddx(decalSpaceScenePos), ddy(decalSpaceScenePos)));//reconstruct scene hard normal using scene pos ddx&ddy

// compare scene hard normal with decal projector's dir, decalSpaceHardNormal.z equals dot(decalForwardDir,sceneHardNormalDir)
shouldClip = decalSpaceHardNormal.z > _ProjectionAngleDiscardThreshold ? 0 : 1;
#endif
```

``` hlsl
vert:
    half3 viewPos = mul(MV, positionOS);
    half3 rayVS = viewPos / viewPos.z;
    rayWS = mul((half3x3)I_V, rayVS);
    rayOS = mul((half3x3)I_M, rayVS);

frag:
    half3 positionVS = rayVS * depth;
    half3 positionDecal = mul(half4(positionVS, 1.0), I_VP);

    half3 positionWS = rayWS * depth + _WorldSpaceViewPos;
    half3 positionDecal = mul(I_M, half4(positionWS, 1.0));

    half3 positionDecal = rayOS * depth + _ObjectSpaceViewPos;
```

``` hlsl
// ref: https://blog.naver.com/eryners/110176182240

float4 screenPos = ComputeScreenPos(positionCS);
float2 screenSpaceUV = screenPos.xy / screenPos.w;

half2 depthUV;
depthUV.x =  screenSpaceUV.x * 0.5 + 0.5;
depthUV.y = -screenSpaceUV.y * 0.5 + 0.5;

// TopRight
// DirectX 기준
// 근평면의 경우 -1, -1, 0
// 원평면의 경우 1, 1, 1
// OpenGL 기준
// 근평면의 경우 -1, -1, -1
// 원평면의 경우 1, 1, 1

depthUV += ScreenDimension.zw; // half-pixel Offset basically.

half sceneDepth = SampleSceneDepth(depthUV);
half2 Deproject;
Deproject.x = ProjectionMatrix.M11;
Deproject.y = ProjectionMatrix.M22;
half4 scenePositionVS = half4(positionCS.xy * sceneDepth / (Deproject.xy * positionCS.w) , -depth, 1);

position = mul(scenePositionVS, I_MV);

// 0.5보다 크면 상자 밖임. 클립!
clip(0.5 - abs(position.xyz));

// unity cube's [-0.5,0.5] vertex pos range to [0,1] uv
half2 decalUV = position.xz + 0.5;


clip(0.5 - abs(position.xyz) - shouldClip);
```

``` hlsl
// com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl
#define UNITY_MATRIX_I_VP  unity_MatrixInvVP
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
