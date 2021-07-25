# Depth

``` hlsl
half3 perspectiveDivide = IN.positionNDC.xyz / IN.positionNDC.w;
half2 uv_Screen         = perspectiveDivide.xy;

half  sceneRawDepth     = SampleSceneDepth(uv_Screen);
half  sceneEyeDepth     = LinearEyeDepth(sceneRawDepth, _ZBufferParams);
half  scene01Depth      = Linear01Depth (sceneRawDepth, _ZBufferParams);
```



[SampleSceneDepth](https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl)

``` hlsl
// com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl

float SampleSceneDepth(float2 uv)
{
    return SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, UnityStereoTransformScreenSpaceTex(uv)).r;
}
```

[_ZBufferParams](https://docs.unity3d.com/Manual/SL-UnityShaderVariables.html)
Used to linearize Z buffer values. x is (1-far/near), y is (far/near), z is (x/far) and w is (y/far).
|   |              |
|---|--------------|
| x | 1 - far/near |
| y | far / near   |
| z | x / far      |
| w | y / far      |


[Linear01Depth / LinearEyeDepth](https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl)

``` hlsl
// com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl

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

[_ProjectionParams](https://docs.unity3d.com/Manual/SL-UnityShaderVariables.html)

|   |                                         |
|---|-----------------------------------------|
| x | 1.0 (or –1.0 flipped projection matrix) |
| y | near plane                              |
| z | far plane                               |
| w | 1/FarPlane                              |

![ndc.png](./doc_res/ndc.png)

``` hlsl
// vert
VertexPositionInputs vertexInputs = GetVertexPositionInputs(IN.positionOS.xyz);
OUT.positionNDC = vertexInputs.positionNDC;

// frag
half2 screenUV = IN.positionNDC.xy / IN.positionNDC.w;
half sceneRawDepth = SampleSceneDepth(screenUV);

// --------------------------------------------
// 0 ~ 1을 _ProjectionParams.z : far plane 으로 늘려주자
half scene01Depth = Linear01Depth(sceneRawDepth, _ZBufferParams);   //  [Near / Far, 1]
half sceneEyeDepth = scene01Depth * _ProjectionParams.z;            //  [Near, Far]
// -----------------------------------------------
half sceneEyeDepth = LinearEyeDepth(sceneRawDepth, _ZBufferParams); //  [Near, Far]
// -----------------------------------------------
float fragmentEyeDepth = positionNDC.w;
// -----------------------------------------------
float fragmentEyeDepth = -positionWS.z;
// -----------------------------------------------

// 물체와의 거리를 빼면
half depth = sceneEyeDepth - fragmentEyeDepth;

// 얼마나 앞에 나와있는지 알 수 있다.
half intersectGradient = 1 - min(depth, 1.0f);
```
