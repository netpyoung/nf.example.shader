# nf.example.shader

- 셰이더 모음집
- 자료가 파편화되어있고 기억력 부족이라 보존용으로 만듬.

- URL : <https://netpyoung.github.io/nf.example.shader/>





---------
14부터 Blit함수 사용을 권장하지 않음. => Blitter를 사용 권장
- Blit API만으로는 내부에서 암시적으로 변경하는게 있다.
- URP XR과 통합할때 문제가 된다.
- NativeRenderPass, RenderGraph와 호환되지 않는다.
  
https://docs.unity3d.com/Packages/com.unity.render-pipelines.universal@14.0/manual/customize/blit-overview.html


Blitter.BlitCameraTexture

- https://docs.unity3d.com/Packages/com.unity.render-pipelines.universal@17.0/manual/shader-stripping.html
- https://docs.unity3d.com/Packages/com.unity.render-pipelines.universal@17.0/manual/customize/custom-pass-injection-points.html

``` cs
CommandBuffer cmd = CommandBufferPool.Get(RENDER_TAG);
Blit(cmd, ref renderingData, _material); // ref renderingData: urp12 swap buffer
context.ExecuteCommandBuffer(cmd);
CommandBufferPool.Release(cmd);
```


``` txt
The legacy CommandBuffer.Blit API
Avoid using the CommandBuffer.Blit API in URP projects.

The CommandBuffer.Blit API is the legacy API. It implicitly runs extra operations related to changing states, binding textures, and setting render targets. Those operations happen under the hood in SRP projects and are not transparent to the user.

The API has compatibility issues with the URP XR integration. Using cmd.Blit might implicitly enable or disable XR shader keywords, which breaks XR SPI rendering.

The CommandBuffer.Blit API is not compatible with NativeRenderPass and RenderGraph.

Similar considerations apply to any utilities or wrappers relying on cmd.Blit internally, RenderingUtils.Blit is one such example.
```

``` txt
Use the Blitter API in URP projects. This API does not rely on legacy logic, and is compatible with XR, native Render Passes, and other SRP APIs.
```

https://docs.unity3d.com/Packages/com.unity.render-pipelines.universal@17.0/manual/renderer-features/how-to-fullscreen-blit.html

``` cs

using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

internal class ColorBlitRendererFeature : ScriptableRendererFeature
{
    public Shader m_Shader;
    public float m_Intensity;

    Material m_Material;

    ColorBlitPass m_RenderPass = null;

    public override void AddRenderPasses(ScriptableRenderer renderer,
                                    ref RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType == CameraType.Game)
            renderer.EnqueuePass(m_RenderPass);
    }

    public override void SetupRenderPasses(ScriptableRenderer renderer,
                                        in RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType == CameraType.Game)
        {
            // Calling ConfigureInput with the ScriptableRenderPassInput.Color argument
            // ensures that the opaque texture is available to the Render Pass.
            m_RenderPass.ConfigureInput(ScriptableRenderPassInput.Color);
            m_RenderPass.SetTarget(renderer.cameraColorTargetHandle, m_Intensity);
        }
    }

    public override void Create()
    {
        m_Material = CoreUtils.CreateEngineMaterial(m_Shader);
        m_RenderPass = new ColorBlitPass(m_Material);
    }

    protected override void Dispose(bool disposing)
    {
        CoreUtils.Destroy(m_Material);
    }
}

internal class ColorBlitPass : ScriptableRenderPass
{
    ProfilingSampler m_ProfilingSampler = new ProfilingSampler("ColorBlit");
    Material m_Material;
    RTHandle m_CameraColorTarget;
    float m_Intensity;

    public ColorBlitPass(Material material)
    {
        m_Material = material;
        renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
    }

    public void SetTarget(RTHandle colorHandle, float intensity)
    {
        m_CameraColorTarget = colorHandle;
        m_Intensity = intensity;
    }

    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
        ConfigureTarget(m_CameraColorTarget);
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        var cameraData = renderingData.cameraData;
        if (cameraData.camera.cameraType != CameraType.Game)
            return;

        if (m_Material == null)
            return;

        CommandBuffer cmd = CommandBufferPool.Get();
        using (new ProfilingScope(cmd, m_ProfilingSampler))
        {
            m_Material.SetFloat("_Intensity", m_Intensity);
            Blitter.BlitCameraTexture(cmd, m_CameraColorTarget, m_CameraColorTarget, m_Material, 0);
        }
        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();

        CommandBufferPool.Release(cmd);
    }
}
```

``` hlsl
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
// The Blit.hlsl file provides the vertex shader (Vert),
// input structure (Attributes) and output strucutre (Varyings)
#include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

#pragma vertex Vert
TEXTURE2D_X(_CameraOpaqueTexture);
SAMPLER(sampler_CameraOpaqueTexture);


```