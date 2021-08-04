using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class Feature_HelloSRP : ScriptableRendererFeature
{
    class Pass_HelloSRP : ScriptableRenderPass
    {
        const string RENDER_TAG = nameof(Pass_HelloSRP);

        Material _material;
        RenderTargetIdentifier _currentTarget;
        RenderTargetHandle _destination;

        public Pass_HelloSRP(Material material)
        {
            _material = material;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get(RENDER_TAG);
            Blit(cmd, _currentTarget, _destination.Identifier(), _material);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        internal void Setup(RenderTargetIdentifier cameraColorTarget, RenderTargetHandle cameraHandle)
        {
            this._currentTarget = cameraColorTarget;
            this._destination = cameraHandle;
        }
    }

    Pass_HelloSRP _pass;
    public Material Material;

    public override void Create()
    {
        _pass = new Pass_HelloSRP(Material);
        _pass.renderPassEvent = RenderPassEvent.AfterRenderingPostProcessing;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        RenderTargetHandle cameraHandle = RenderTargetHandle.CameraTarget;
        _pass.Setup(renderer.cameraColorTarget, cameraHandle);
        renderer.EnqueuePass(_pass);
    }
}
