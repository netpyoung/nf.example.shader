using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class Feature_PrintDepthMap : ScriptableRendererFeature
{
    class Pass_PrintDepthMap : ScriptableRenderPass
    {
        const string RENDER_TAG = nameof(Pass_PrintDepthMap);

        private readonly Material _material;
        private Volume_PrintDepthMap _depthMap;
        private RTHandle _cameraColorTargetHandle;

        public Pass_PrintDepthMap(Material material)
        {
            _material = material;
        }

        internal void Setup(RTHandle cameraColorTargetHandle)
        {
            _cameraColorTargetHandle = cameraColorTargetHandle;
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            ConfigureTarget(_cameraColorTargetHandle);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CameraData cameraData = renderingData.cameraData;
            if (cameraData.camera.cameraType != CameraType.Game)
            {
                return;
            }

            if (_material == null)
            {
                return;
            }

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
            Blitter.BlitCameraTexture(cmd, _cameraColorTargetHandle, _cameraColorTargetHandle, _material, 0);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }

    public Material Material;
    private Pass_PrintDepthMap _pass;

    public override void Create()
    {
        _pass = new Pass_PrintDepthMap(Material);
        _pass.renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType == CameraType.Game)
        {
            renderer.EnqueuePass(_pass);
        }
    }

    public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType == CameraType.Game)
        {
            _pass.ConfigureInput(ScriptableRenderPassInput.Color);
            _pass.Setup(renderer.cameraColorTargetHandle);
        }
    }
}
