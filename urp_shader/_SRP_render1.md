# a

``` cs
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
    // https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.universal/Runtime/Passes/DrawObjectsPass.cs

/// ---------------- RenderPassEvent.BeforeRenderingSkybox
m_DrawSkyboxPass = new DrawSkyboxPass(RenderPassEvent.BeforeRenderingSkybox);
    camera.projectionMatrix = cameraData.GetProjectionMatrix(0);
    camera.worldToCameraMatrix = cameraData.GetViewMatrix(0);
    context.DrawSkybox(camera);
    context.Submit(); // Submit and execute the skybox pass before resetting the matrices
    camera.ResetProjectionMatrix();
    camera.ResetWorldToCameraMatrix();
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
        ref CameraData cameraData = ref renderingData.cameraData;
        RenderTargetIdentifier cameraTarget = (cameraData.targetTexture != null) ? new RenderTargetIdentifier(cameraData.targetTexture) : BuiltinRenderTextureType.CameraTarget;
        cmd.SetRenderTarget(BuiltinRenderTextureType.CameraTarget,
            RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store, // color
            RenderBufferLoadAction.DontCare, RenderBufferStoreAction.DontCare); // depth
        cmd.Blit(m_Source, cameraTarget, m_BlitMaterial);
```

=======================

``` cs
CommandBuffer cmd = CommandBufferPool.Get(string name);

// NOTE: Do NOT mix ProfilingScope with named CommandBuffers
CommandBuffer cmd = CommandBufferPool.Get();

CommandBufferPool.Release(cmd);
```

[struct RenderTargetIdentifier](https://github.com/Unity-Technologies/UnityCsReference/blob/master/Runtime/Export/Graphics/GraphicsEnums.cs)
[struct ScriptableRenderContext](https://github.com/Unity-Technologies/UnityCsReference/blob/master/Runtime/Export/RenderPipeline/ScriptableRenderContext.cs)

=============
custom

- CustomRenderer
- CommandBufferPool

``` cs
[CreateAssetMenu(menuName = "Rendering/My Pipeline")]
public class MyPipelineAsset : RenderPipelineAsset
{
}

public class MyPipeline : RenderPipeline
{

}
```

``` cs

// Update the value of built-in shader variables, based on the current Camera
context.SetupCameraProperties(camera);
```