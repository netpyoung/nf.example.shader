using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class Feature_PrintDepthMap : ScriptableRendererFeature
{
    class Pass_PrintDepthMap : ScriptableRenderPass
    {
        const string RENDER_TAG = "PrintDepthMapPass";

        Volume_PrintDepthMap _depthMap;
        Material _material;
        RenderTargetIdentifier _currentTarget;
        RenderTargetHandle _destination;

        public Pass_PrintDepthMap(Material material)
        {
            _material = material;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (!renderingData.cameraData.postProcessEnabled)
            {
                return;
            }

            VolumeStack stack = VolumeManager.instance.stack;
            _depthMap = stack.GetComponent<Volume_PrintDepthMap>();

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

            Blit(cmd, ref renderingData, _material);
        }

        internal void Setup(RenderTargetIdentifier cameraColorTarget, RenderTargetHandle cameraHandle)
        {
            this._currentTarget = cameraColorTarget;
            this._destination = cameraHandle;
        }
    }

    Pass_PrintDepthMap _pass;
    public Material Material;

    public override void Create()
    {
        _pass = new Pass_PrintDepthMap(Material);
        _pass.renderPassEvent = RenderPassEvent.AfterRenderingPostProcessing;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        RenderTargetHandle cameraHandle = RenderTargetHandle.CameraTarget;
        _pass.Setup(renderer.cameraColorTarget, cameraHandle);
        renderer.EnqueuePass(_pass);
    }
}
