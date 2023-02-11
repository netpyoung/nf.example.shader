using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class Feature_HelloSRP : ScriptableRendererFeature
{
    class Pass_HelloSRP : ScriptableRenderPass
    {
        const string RENDER_TAG = nameof(Pass_HelloSRP);

        Material _material;

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
            Blit(cmd, ref renderingData, _material); // ref renderingData: urp12 swap buffer
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
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
}
