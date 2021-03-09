using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class PrintDepthMapRendererFeature : ScriptableRendererFeature
{
    class PrintDepthMapPass : ScriptableRenderPass
    {
        const string RENDER_TAG = "PrintDepthMapPass";

        VolumePrintDepthMap _depthMap;
        Material _material;
        RenderTargetIdentifier _currentTarget;
        RenderTargetHandle _destination;

        public PrintDepthMapPass(Material material)
        {
            _material = material;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (!renderingData.cameraData.postProcessEnabled)
            {
                return;
            }

            var stack = VolumeManager.instance.stack;
            _depthMap = stack.GetComponent<VolumePrintDepthMap>();

            if (_depthMap == null)
            {
                return;
            }

            if (!_depthMap.IsActive())
            {
                return;
            }

            CommandBuffer cmd = CommandBufferPool.Get(RENDER_TAG);
            Render(cmd, ref renderingData);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        void Render(CommandBuffer cmd, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.isSceneViewCamera)
            {
                return;
            }

            Blit(cmd, _currentTarget, _destination.Identifier(), _material);
        }

        internal void Setup(RenderTargetIdentifier cameraColorTarget, RenderTargetHandle cameraHandle)
        {
            this._currentTarget = cameraColorTarget;
            this._destination = cameraHandle;
        }
    }

    PrintDepthMapPass _pass;
    public Material Material;

    public override void Create()
    {
        _pass = new PrintDepthMapPass(Material);
        _pass.renderPassEvent = RenderPassEvent.AfterRenderingPostProcessing;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        RenderTargetHandle cameraHandle = RenderTargetHandle.CameraTarget;
        _pass.Setup(renderer.cameraColorTarget, cameraHandle);
        renderer.EnqueuePass(_pass);
    }
}
