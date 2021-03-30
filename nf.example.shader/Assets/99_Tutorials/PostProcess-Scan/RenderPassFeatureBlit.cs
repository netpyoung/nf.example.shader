using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class RenderPassFeatureBlit : ScriptableRendererFeature
{
    class RenderPassBlit : ScriptableRenderPass
    {
        private RenderTargetIdentifier _source;
        private RenderTargetHandle _tempTexture;
        private RenderPassFeatureBlit _feature;

        public RenderPassBlit(RenderPassFeatureBlit feature)
        {
            _feature = feature;
            _tempTexture.Init("_TempTex");
        }

        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in an performance manner.
        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get($"{nameof(RenderPassBlit)}");
            {
                RenderTextureDescriptor desc = renderingData.cameraData.cameraTargetDescriptor;
                desc.depthBufferBits = 0;
                cmd.GetTemporaryRT(_tempTexture.id, desc, FilterMode.Bilinear);

                //Blit(cmd, _source, _tempTexture.Identifier(), _feature.material, 0);
                //Blit(cmd, _tempTexture.Identifier(), _source);

                //Blit(cmd, _source, _tempTexture.Identifier());
                Blit(cmd, _tempTexture.Identifier(), _source, _feature.material, 0);

                context.ExecuteCommandBuffer(cmd);
            }
            CommandBufferPool.Release(cmd);
        }

        /// Cleanup any allocated resources that were created during the execution of this render pass.
        public override void FrameCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(_tempTexture.id);
        }

        internal void SetSource(RenderTargetIdentifier cameraColorTarget)
        {
            this._source = cameraColorTarget;
        }
    }

    RenderPassBlit _scriptablePass;

    public Material material;

    public override void Create()
    {
        _scriptablePass = new RenderPassBlit(this);

        // Configures where the render pass should be injected.
        //m_ScriptablePass.renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
        _scriptablePass.renderPassEvent = RenderPassEvent.AfterRendering;
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        _scriptablePass.SetSource(renderer.cameraColorTarget);
        renderer.EnqueuePass(_scriptablePass);
    }
}


