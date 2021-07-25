# Depth

- LinearEyeDepth : distance from the eye in world units
- Linear01Depth : distance from the eye in [0;1]

``` hlsl
half3 pd            = IN.positionNDC.xyz / IN.positionNDC.w; // perspectiveDivide
half2 uv_Screen     = pd.xy;

half  sceneRawDepth = SampleSceneDepth(uv_Screen);
half  sceneEyeDepth = LinearEyeDepth(sceneRawDepth, _ZBufferParams);
half  scene01Depth  = Linear01Depth (sceneRawDepth, _ZBufferParams);
```

- [SampleSceneDepth](https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl)
- [Linear01Depth / LinearEyeDepth](https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl)

``` hlsl
/// com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl
float SampleSceneDepth(float2 uv)
{
    return SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, UnityStereoTransformScreenSpaceTex(uv)).r;
}

/// com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl
// Z buffer to linear 0..1 depth (0 at camera position, 1 at far plane).
// Does NOT work with orthographic projections.
// Does NOT correctly handle oblique view frustums.
// zBufferParam = { (f-n)/n, 1, (f-n)/n*f, 1/f }
float Linear01Depth(float depth, float4 zBufferParam)
{
    return 1.0 / (zBufferParam.x * depth + zBufferParam.y);
}

// Z buffer to linear depth.
// Does NOT correctly handle oblique view frustums.
// Does NOT work with orthographic projection.
// zBufferParam = { (f-n)/n, 1, (f-n)/n*f, 1/f }
float LinearEyeDepth(float depth, float4 zBufferParam)
{
    return 1.0 / (zBufferParam.z * depth + zBufferParam.w);
}
```

| [_ZBufferParams](https://docs.unity3d.com/Manual/SL-UnityShaderVariables.html) | x             | y        | z     | w     |
|--------------------------------------------------------------------------------|---------------|----------|-------|-------|
| DirectX                                                                        | -1 + far/near | 1        | x/far | 1/far |
| OpenGL                                                                         | 1 - far/near  | far/near | x/far | y/far |

![./res/EyeDepth.png](../res/EyeDepth.png)

## depth buffer value non-linear (in view space)

![./res/DepthComparison.png](../res/DepthComparison.png)

## Sample

``` hlsl
// vert
float currEyeDepth = -positionVS.z;
float curr01Depth = -positionVS.z * _ProjectionParams.w;
float4 positionNDC = GetVertexPositionInputs(positionOS).positionNDC;

// frag
half2 uv_Screen = IN.positionNDC.xy / IN.positionNDC.w;
half sceneRawDepth = SampleSceneDepth(uv_Screen);

// --------------------------------------------
half scene01Depth = Linear01Depth(sceneRawDepth, _ZBufferParams);   //  [near/far, 1]

// -----------------------------------------------
// scene01Depth을 _ProjectionParams.z(far plane)으로 늘리면 sceneEyeDepth
half sceneEyeDepth = scene01Depth * _ProjectionParams.z;            //  [near, far]
half sceneEyeDepth = LinearEyeDepth(sceneRawDepth, _ZBufferParams); //  [near, far]

// -----------------------------------------------
// 물체와의 거리를 빼면, 얼마나 앞에 나와있는지 알 수 있다.
half diffEyeDepth = sceneEyeDepth - IN.currEyeDepth;
half intersectGradient = 1 - min(diffEyeDepth, 1.0f);
```

## Reversed-z

TODO

- <https://developer.nvidia.com/content/depth-precision-visualized>

## Ref

- <https://www.cyanilux.com/tutorials/depth/>
- <https://beta.unity3d.com/talks/Siggraph2011_SpecialEffectsWithDepth_WithNotes.pdf>
