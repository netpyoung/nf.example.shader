# SRP Note

https://docs.unity3d.com/ScriptReference/Rendering.RenderPipeline.html

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

``` cs
bool needsDepth   = (pass.input & ScriptableRenderPassInput.Depth) != ScriptableRenderPassInput.None;
bool needsNormals = (pass.input & ScriptableRenderPassInput.Normal) != ScriptableRenderPassInput.None;
bool needsColor   = (pass.input & ScriptableRenderPassInput.Color) != ScriptableRenderPassInput.None;
bool needsMotion  = (pass.input & ScriptableRenderPassInput.Motion) != ScriptableRenderPassInput.None;
```

m_DepthPrepass = new DepthOnlyPass(RenderPassEvent.BeforeRenderingPrePasses, RenderQueueRange.opaque, data.opaqueLayerMask);
m_DepthNormalPrepass = new DepthNormalOnlyPass(RenderPassEvent.BeforeRenderingPrePasses, RenderQueueRange.opaque, data.opaqueLayerMask);
m_MotionVectorPass = new MotionVectorRenderPass(m_CameraMotionVecMaterial, m_ObjectMotionVecMaterial);

 if (this.renderingMode == RenderingMode.Forward)
{
    m_PrimedDepthCopyPass = new CopyDepthPass(RenderPassEvent.AfterRenderingPrePasses, m_CopyDepthMaterial);
}



GraphicsSettings.useScriptableRenderPipelineBatching = true;

bool isSceneViewCam = camera.cameraType == CameraType.SceneView;
bool isSceneViewCamera = cameraData.isSceneViewCamera;

drawSettingsDefault.SetShaderPassName(1, TAG_SRPDefaultUnlit); 

[RenderSingleCamera](https://github.com/Unity-Technologies/Graphics/blob/53fed35b0ed491fda85d87c8b39a3175c40d7fc3/com.unity.render-pipelines.universal/Runtime/UniversalRenderPipeline.cs#L348)


contex.BeginScopedRenderPass
context.BeginScopedSubPass


// ConfigureInput(ScriptableRenderPassInput.Depth);
// ConfigureInput(ScriptableRenderPassInput.Normal);
https://forum.unity.com/threads/will-camera-depth-normal-textures-be-added-fto-urp.924398/
https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl


- commandbuffer
  - DrawProcedural
  - DrawMesh
  - DrawRenderer

## ETC
https://blog.naver.com/canny708/221878564749

## Deferred
https://github.com/cinight/CustomSRP/blob/master/Assets/SRP0802_RenderPass/SRP0802.cs
https://github.com/cinight/CustomSRP/blob/master/Assets/SRP0803_MultiRenderTarget/SRP0803.cs

RGBM - https://kblog.popekim.com/2013/11/blendable-rgbm.html, http://egloos.zum.com/cagetu/v/5697725

MRT
[ 디퍼트 라이팅 엔진에서 Oren-Nayar 조명 쓰기 ](https://kblog.popekim.com/2011/11/oren-nayar.html)
[ 새로운 기법 != 새 장난감 ](https://kblog.popekim.com/2012/02/blog-post.html)

https://github.com/devknit/RenderPipeline/blob/master/Runtime/RenderPipeline.cs

=========================

RenderTextureDescriptor | RenderTexture를 만드는 정보
RenderTargetIdentifier  | RenderTexture의 ID (CommandBuffer에서 사용)


ConfigureTarget(RenderTargetIdentifier) ??
https://docs.unity3d.com/Packages/com.unity.render-pipelines.universal@12.0/api/UnityEngine.Rendering.Universal.ScriptableRenderPass.html#UnityEngine_Rendering_Universal_ScriptableRenderPass_ConfigureTarget_UnityEngine_Rendering_RenderTargetIdentifier_
Configures render targets for this render pass. Call this instead of CommandBuffer.SetRenderTarget. This method should be called inside Configure.

https://docs.unity3d.com/ScriptReference/Rendering.CommandBuffer.SetRenderTarget.html




Blit
https://docs.unity3d.com/ScriptReference/Rendering.CommandBuffer.Blit.html

``` cs
// ScriptableRenderPass.cs

/// <summary>
/// Add a blit command to the context for execution. This changes the active render target in the ScriptableRenderer to
/// destination.
/// </summary>
/// <param name="cmd">Command buffer to record command for execution.</param>
/// <param name="source">Source texture or target identifier to blit from.</param>
/// <param name="destination">Destination texture or target identifier to blit into. This becomes the renderer active render target.</param>
/// <param name="material">Material to use.</param>
/// <param name="passIndex">Shader pass to use. Default is 0.</param>
/// <seealso cref="ScriptableRenderer"/>
public void Blit(CommandBuffer cmd, RenderTargetIdentifier source, RenderTargetIdentifier destination, Material material = null, int passIndex = 0)
{
    ScriptableRenderer.SetRenderTarget(cmd, destination, BuiltinRenderTextureType.CameraTarget, clearFlag, clearColor);
    cmd.Blit(source, destination, material, passIndex);
}
```



``` cs
// https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.universal/Runtime/Passes/ScriptableRenderPass.cs

// ScriptableRenderPass.cs

/// This method is called by the renderer before rendering a camera
public virtual void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)

    /// This method is called by the renderer before executing the render pass.
    public virtual void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)

    /// Execute the pass
    public abstract void Execute(ScriptableRenderContext context, ref RenderingData renderingData);

/// Called upon finish rendering a camera
// - framecleanup deprecated
public virtual void OnCameraCleanup(CommandBuffer cmd)

/// Called upon finish rendering a camera stack
public virtual void OnFinishCameraStackRendering(CommandBuffer cmd)
```

``` cs
// https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.universal/Runtime/ScriptableRenderer.cs
// ScriptableRenderer.cs

Execute
InternalStartRendering
  - OnCameraSetup
ExecuteBlock
  ExecuteRenderPass
    - Configure
    - Execute
InternalFinishRendering
  - OnCameraCleanup
  - OnFinishCameraStackRendering

protected void AddRenderPasses(ref RenderingData renderingData)
  - AddRenderPasses
```

``` cs
// https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.universal/Runtime/ScriptableRendererFeature.cs
AddRenderPasses

```

``` cs
// https://github.com/Unity-Technologies/UnityCsReference/blob/master/Runtime/Export/RenderPipeline/RenderPipeline.cs
// https://github.com/Unity-Technologies/UnityCsReference/blob/master/Runtime/Export/RenderPipeline/RenderPipelineAsset.cs
```

``` cs
// https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.universal/Runtime/UniversalRenderPipeline.cs
```