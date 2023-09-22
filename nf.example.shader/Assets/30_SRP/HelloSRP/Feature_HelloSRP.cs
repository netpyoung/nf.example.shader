using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class Feature_HelloSRP : ScriptableRendererFeature
{
    class Pass_HelloSRP : ScriptableRenderPass
    {
        const string RENDER_TAG = nameof(Pass_HelloSRP);

        private readonly Material _material;
        private RTHandle _cameraColorTargetHandle;

        public Pass_HelloSRP(Material material)
        {
            _material = material;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.isSceneViewCamera)
            {
                return;
            }
            CommandBuffer cmd = CommandBufferPool.Get(RENDER_TAG);
            cmd.Blit(renderingData.cameraData.targetTexture, _cameraColorTargetHandle, _material);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        internal void Setup(RTHandle cameraColorTargetHandle)
        {
            _cameraColorTargetHandle = cameraColorTargetHandle;
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
        renderer.EnqueuePass(_pass);
    }

    public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
    {
        _pass.Setup(renderer.cameraColorTargetHandle);
    }
}
