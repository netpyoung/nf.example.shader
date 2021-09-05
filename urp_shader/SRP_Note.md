# SRP(Scriptable Render Pipeline) Note

| .universal              |                                                |
| ----------------------- | ---------------------------------------------- |
| UniversalRenderPipeline | 렌더러들을 가지고 렌더링을 시켜주는것          |
| - renderer.Setup        | UniversalRenderer에서 pass들을 큐에 넣는다.    |
| - renderer.Execute      | ScriptableRenderer에서 큐에 넣은 pass들을 실행 |
| UniversalRenderer       | ScriptableRenderPass들을 가지고 있음.          |
| ScriptableRenderer      | ScriptableRendererFeature들을 가지고 있음      |

``` txt
[에디터] 씬뷰 월드 지오메트리 뿌리기

컬링
카메라 관련 셰이더 변수 설정
카메라 클리어
SRP배칭 설정

[깊이] 불투명 그리기
[깊이] 투명 그리기

// TODO 모션벡터

스카이박스                   
[오브젝트] 불투명 그리기
[오브젝트] 투명 그리기

포스트 프로세스

[에디터] 씬뷰 Gizmo 그리기

```

| 클래스 / 구조체         | 종류             | 링크                                                                                                                                                                                                                                                                |
| ----------------------- | ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| RenderPipelineAsset     | UnityCsReference | [src](https://github.com/Unity-Technologies/UnityCsReference/blob/master/Runtime/Export/RenderPipeline/RenderPipelineAsset.cs)                                                                                                                                      |
| RenderPipeline          | UnityCsReference | [src](https://github.com/Unity-Technologies/UnityCsReference/blob/master/Runtime/Export/RenderPipeline/RenderPipeline.cs)                                                                                                                                           |
| ScriptableRenderContext | UnityCsReference | [src](https://github.com/Unity-Technologies/UnityCsReference/blob/master/Runtime/Export/RenderPipeline/ScriptableRenderContext.cs)                                                                                                                                  |
| CommandBuffer           | UnityCsReference | [src1](https://github.com/Unity-Technologies/UnityCsReference/blob/master/Runtime/Export/Graphics/RenderingCommandBuffer.cs), [src2](https://github.com/Unity-Technologies/UnityCsReference/blob/master/Runtime/Export/Graphics/RenderingCommandBuffer.bindings.cs) |

| 클래스 / 구조체              | 종류       | 링크                                                                                                                                                |
| ---------------------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| UniversalRenderPipelineAsset | .universal | [src](https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.universal/Runtime/Data/UniversalRenderPipelineAsset.cs) |
| UniversalRenderPipeline      | .universal | [src](https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.universal/Runtime/UniversalRenderPipeline.cs)           |
| ScriptableRenderer           | .universal | [src](https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.universal/Runtime/ScriptableRenderer.cs)                |
| UniversalRenderer            | .universal | [src](https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.universal/Runtime/UniversalRenderer.cs)                 |
| ScriptableRenderPass         | .universal | [src](https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.universal/Runtime/Passes/ScriptableRenderPass.cs)       |
| ScriptableRendererFeature    | .universal | [src](https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.universal/Runtime/ScriptableRendererFeature.cs)         |

## Pipeline

``` cs
// RenderPipeline.cs
// https://github.com/Unity-Technologies/UnityCsReference/blob/master/Runtime/Export/RenderPipeline/RenderPipeline.cs
protected abstract void Render(ScriptableRenderContext context, List<Camera> cameras);
```

``` cs
// UniversalRenderPipeline.cs
// UniversalRenderPipeline : RenderPipeline
// https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.universal/Runtime/UniversalRenderPipeline.cs

protected override void Render(ScriptableRenderContext renderContext, List<Camera> cameras)
{
    BeginContextRendering(renderContext, cameras);
    GraphicsSettings.useScriptableRenderPipelineBatching = asset.useSRPBatcher;  // SRP

    SortCameras(cameras);
    for (int i = 0; i < cameras.Count; ++i)
    {
        var camera = cameras[i];
        BeginCameraRendering(renderContext, camera);
        UpdateVolumeFramework(camera, null);
        RenderSingleCamera(renderContext, camera);
        EndCameraRendering(renderContext, camera);
    }
    EndContextRendering(renderContext, cameras);
}

public static void RenderSingleCamera(ScriptableRenderContext context, Camera camera)
{
}

static void RenderSingleCamera(ScriptableRenderContext context, CameraData cameraData, bool anyPostProcessingEnabled)
{
  if (!TryGetCullingParameters(cameraData, out var cullingParameters))
    return;
  renderer.Clear(cameraData.renderType);
  renderer.OnPreCullRenderPasses(in cameraData);
  renderer.SetupCullingParameters(ref cullingParameters, ref cameraData);

  ScriptableRenderContext.EmitWorldGeometryForSceneView(camera); // 에디터

  var cullResults = context.Cull(ref cullingParameters);
  InitializeRenderingData(asset, ref cameraData, ref cullResults, anyPostProcessingEnabled, out var renderingData);

  renderer.Setup(context, ref renderingData);                    // Setup   !!! UniversalRenderer에서 pass들을 큐에 넣는다.
  renderer.Execute(context, ref renderingData);                  // Execute !!! ScriptableRenderer에서 큐에 넣은 pass들을 실행
  CleanupLightData(ref renderingData.lightData);
}
```

``` cs
// UniversalRenderer.cs
// UniversalRenderer : ScriptableRenderer
// https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.universal/Runtime/UniversalRenderer.cs

// DrawSkyboxPass : ScriptableRenderPass
// OpaquePostProcessPass : ScriptableRenderPass
// ScreenSpaceShadowResolvePass : ScriptableRenderPass
// SetupForwardRenderingPass : ScriptableRenderPass
// ...

public UniversalRenderer(UniversalRendererData data) : base(data)
{
    /// ---------------- RenderPassEvent.BeforeRenderingShadows
    m_MainLightShadowCasterPass = new MainLightShadowCasterPass(RenderPassEvent.BeforeRenderingShadows);
    m_AdditionalLightsShadowCasterPass = new AdditionalLightsShadowCasterPass(RenderPassEvent.BeforeRenderingShadows);

    /// ---------------- RenderPassEvent.BeforeRenderingPrePasses
    m_DepthPrepass = new DepthOnlyPass(RenderPassEvent.BeforeRenderingPrePasses, RenderQueueRange.opaque, data.opaqueLayerMask);
    m_DepthNormalPrepass = new DepthNormalOnlyPass(RenderPassEvent.BeforeRenderingPrePasses, RenderQueueRange.opaque, data.opaqueLayerMask);
    [post] m_ColorGradingLutPass = new ColorGradingLutPass(RenderPassEvent.BeforeRenderingPrePasses, data);
    /// ---------------- RenderPassEvent.AfterRenderingPrePasses
    m_PrimedDepthCopyPass = new CopyDepthPass(RenderPassEvent.AfterRenderingPrePasses, m_CopyDepthMaterial);

    /// ---------------- RenderPassEvent.BeforeRenderingOpaques
    m_RenderOpaqueForwardPass = new DrawObjectsPass(URPProfileId.DrawOpaqueObjects, true, RenderPassEvent.BeforeRenderingOpaques, RenderQueueRange.opaque, data.opaqueLayerMask, m_DefaultStencilState, stencilData.stencilReference);

    /// ---------------- RenderPassEvent.BeforeRenderingSkybox
    m_DrawSkyboxPass = new DrawSkyboxPass(RenderPassEvent.BeforeRenderingSkybox);
    /// ---------------- RenderPassEvent.AfterRenderingSkybox  
    m_CopyDepthPass = new CopyDepthPass(RenderPassEvent.AfterRenderingSkybox, m_CopyDepthMaterial);
    m_CopyColorPass = new CopyColorPass(RenderPassEvent.AfterRenderingSkybox, m_SamplingMaterial, m_BlitMaterial);

    /// ---------------- RenderPassEvent.BeforeRenderingTransparents
    m_TransparentSettingsPass = new TransparentSettingsPass(RenderPassEvent.BeforeRenderingTransparents, data.shadowTransparentReceive);
    m_RenderTransparentForwardPass = new DrawObjectsPass(URPProfileId.DrawTransparentObjects, false, RenderPassEvent.BeforeRenderingTransparents, RenderQueueRange.transparent, data.transparentLayerMask, m_DefaultStencilState, stencilData.stencilReference);

    /// ---------------- RenderPassEvent.BeforeRenderingPostProcessing
    m_OnRenderObjectCallbackPass = new InvokeOnRenderObjectCallbackPass(RenderPassEvent.BeforeRenderingPostProcessing);
    [post] m_PostProcessPass = new PostProcessPass(RenderPassEvent.BeforeRenderingPostProcessing, data, m_BlitMaterial);
    /// ---------------- RenderPassEvent.AfterRenderingPostProcessing
    [post] m_FinalPostProcessPass = new PostProcessPass(RenderPassEvent.AfterRenderingPostProcessing, data, m_BlitMaterial);

    /// ---------------- RenderPassEvent.AfterRendering
    m_CapturePass = new CapturePass(RenderPassEvent.AfterRendering);
    m_FinalBlitPass = new FinalBlitPass(RenderPassEvent.AfterRendering + 1, m_BlitMaterial);
}

public override void Setup(ScriptableRenderContext context, ref RenderingData renderingData)
{
    RenderPassInputSummary renderPassInputs = GetRenderPassInputs(ref renderingData);
    // ...
    EnqueuePass(...);
}

private RenderPassInputSummary GetRenderPassInputs(ref RenderingData renderingData)
{
    for (int i = 0; i < activeRenderPassQueue.Count; ++i)
    {
        ScriptableRenderPass pass = activeRenderPassQueue[i];
        bool needsDepth   = (pass.input & ScriptableRenderPassInput.Depth) != ScriptableRenderPassInput.None;
        bool needsNormals = (pass.input & ScriptableRenderPassInput.Normal) != ScriptableRenderPassInput.None;
        bool needsColor   = (pass.input & ScriptableRenderPassInput.Color) != ScriptableRenderPassInput.None;
        bool needsMotion  = (pass.input & ScriptableRenderPassInput.Motion) != ScriptableRenderPassInput.None;
        // ...
    }
}
```

``` cs
// ScriptableRenderer.cs
// https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.universal/Runtime/ScriptableRenderer.cs
public abstract void Setup(ScriptableRenderContext context, ref RenderingData renderingData);

public void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
{
    InternalStartRendering
      - OnCameraSetup                - ScriptableRenderPass
    // 변수셋팅 및 초기화
    // 라이트 설정
    // 카메라 설정
    SetCameraMatrices
    // ExecuteBlock - Opaque
        ExecuteBlock
            ExecuteRenderPass
              - Configure            - ScriptableRenderPass
              - Execute              - ScriptableRenderPass
    // ExecuteBlock - Transparent
    // Gizmos - PreImageEffects
    // DrawWireOverlay
    // Gizmos - PostImageEffects
    InternalFinishRendering
      - OnCameraCleanup              - ScriptableRenderPass
      - OnFinishCameraStackRendering - ScriptableRenderPass
}

protected void AddRenderPasses(ref RenderingData renderingData)
{
    rendererFeatures[i].AddRenderPasses
}

public static void SetCameraMatrices(CommandBuffer cmd, ref CameraData cameraData, bool setInverseMatrices)
```

``` cs
// ScriptableRenderPass.cs
// https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.universal/Runtime/Passes/ScriptableRenderPass.cs

/// This method is called by the renderer before rendering a camera
public virtual void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData);

    /// This method is called by the renderer before executing the render pass.
    public virtual void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor);
    
    /// Execute the pass
    public abstract void Execute(ScriptableRenderContext context, ref RenderingData renderingData);
    
/// Called upon finish rendering a camera
// - framecleanup deprecated
public virtual void OnCameraCleanup(CommandBuffer cmd);

/// Called upon finish rendering a camera stack
public virtual void OnFinishCameraStackRendering(CommandBuffer cmd);


public void Blit(CommandBuffer cmd, RenderTargetIdentifier source, RenderTargetIdentifier destination, Material material = null, int passIndex = 0)
{
    ScriptableRenderer.SetRenderTarget(cmd, destination, BuiltinRenderTextureType.CameraTarget, clearFlag, clearColor);
    cmd.Blit(source, destination, material, passIndex);
}
```

``` cs
// ScriptableRendererFeature.cs
// https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.universal/Runtime/ScriptableRendererFeature.cs

// `Create`시 기본 pass를 만들고, 만들 pass를 `AddRenderPasses`가 호출되면 넘어오는 인자 `ScriptableRenderer renderer`를 이용하여 `renderer.EnqueuePass(pass)`로 패스를 넘겨준다.

Create          // 시리얼라이제이션할때(생성할때)
AddRenderPasses // 카메라 설정할때
```

``` cs
// CommandBufferPool.cs
// https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.core/Runtime/Common/CommandBufferPool.cs

// CommandBufferPool에서 사용하고 CommandBuffer를 릴리즈 시켜줄시, 알아서 Clear시켜준다.
static ObjectPool<CommandBuffer> s_BufferPool = new ObjectPool<CommandBuffer>(null, x => x.Clear());
```

======================================================================================================================================================

| RenderPassEvent               |      |                                                                          |
| ----------------------------- | ---- | ------------------------------------------------------------------------ |
| BeforeRendering               | 0    | 카메라 메트릭스, 스테리오 렌더링 설정이 안된 상태                        |
| BeforeRenderingShadows        | 50   | 카메라 메트릭스, 스테리오 렌더링 설정이 안된 상태                        |
| AfterRenderingShadows         | 100  | 카메라 메트릭스, 스테리오 렌더링 설정이 안된 상태                        |
| BeforeRenderingPrepasses      | 150  | 카메라 메트릭스, 스테리오 렌더링 설정이 완료된 상태                      |
| AfterRenderingPrePasses       | 200  |                                                                          |
| BeforeRenderingGbuffer        | 210  |                                                                          |
| AfterRenderingGbuffer         | 220  |                                                                          |
| BeforeRenderingDeferredLights | 230  |                                                                          |
| AfterRenderingDeferredLights  | 240  |                                                                          |
| BeforeRenderingOpaques        | 250  |                                                                          |
| AfterRenderingOpaques         | 300  |                                                                          |
| BeforeRenderingSkybox         | 350  |                                                                          |
| AfterRenderingSkybox          | 400  |                                                                          |
| BeforeRenderingTransparents   | 450  |                                                                          |
| AfterRenderingTransparents    | 500  |                                                                          |
| BeforeRenderingPostProcessing | 550  |                                                                          |
| AfterRenderingPostProcessing  | 600  | final blit, post-processing AA effects and color grading 적용이 안된상태 |
| AfterRendering                | 1000 | 모든 효과 적용된 상태                                                    |

``` hlsl
Pass
{
    Tags
    {
        // LightMode 태그는 라이팅 파이프 라인에서 패스의 역할을 정의.
        "LightMode" = "CustomLightMode"
    }
}

```

bool isSceneViewCamera = renderingData.cameraData.isSceneViewCamera;

drawSettingsDefault.SetShaderPassName(1, TAG_SRPDefaultUnlit); 

contex.BeginScopedRenderPass
context.BeginScopedSubPass


// ConfigureInput(ScriptableRenderPassInput.Depth);
// ConfigureInput(ScriptableRenderPassInput.Normal);
https://forum.unity.com/threads/will-camera-depth-normal-textures-be-added-fto-urp.924398/
https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl


RenderTextureDescriptor | RenderTexture를 만드는 정보
RenderTargetIdentifier  | RenderTexture의 ID (CommandBuffer에서 사용)


ConfigureTarget(RenderTargetIdentifier) ??
https://docs.unity3d.com/Packages/com.unity.render-pipelines.universal@12.0/api/UnityEngine.Rendering.Universal.ScriptableRenderPass.html#UnityEngine_Rendering_Universal_ScriptableRenderPass_ConfigureTarget_UnityEngine_Rendering_RenderTargetIdentifier_
Configures render targets for this render pass. Call this instead of CommandBuffer.SetRenderTarget. This method should be called inside Configure.

https://docs.unity3d.com/ScriptReference/Rendering.CommandBuffer.SetRenderTarget.html


- commandbuffer
  - DrawProcedural
  - DrawMesh
  - DrawRenderer
