using System;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class Sobel_RenderPassFeature : ScriptableRendererFeature
{
    [SerializeField]
    Sobel_RenderPassSettings _settings = null;
    Sobel_RenderPass _pass;

    public override void Create()
    {
        _pass = new Sobel_RenderPass(_settings);
        _pass.renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
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
    // ====================================================================
    // ====================================================================
    [Serializable]
    public class Sobel_RenderPassSettings
    {
        [Range(0.0005f, 0.0025f)] public float _LineThickness;
    }

    // ====================================================================
    // ====================================================================
    class Sobel_RenderPass : ScriptableRenderPass
    {
        Sobel_RenderPassSettings _settings;
        const int PASS_SobelFilter = 0;

        Material _sobel_material;
        private RTHandle _SobelRT;
        private RTHandle _cameraColorTargetHandle;

        public Sobel_RenderPass(Sobel_RenderPassSettings settings)
        {
            _settings = settings;
            if (_sobel_material == null)
            {
                _sobel_material = CoreUtils.CreateEngineMaterial("Hidden/Sobel");
            }
            _sobel_material.SetFloat("_LineThickness", settings._LineThickness);
        }

        internal void Setup(RTHandle cameraColorTargetHandle)
        {
            _cameraColorTargetHandle = cameraColorTargetHandle;
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            CameraData cameraData = renderingData.cameraData;
            Camera camera = cameraData.camera;
            int w = camera.pixelWidth;
            int h = camera.pixelHeight;
            RenderTextureDescriptor rtd = new RenderTextureDescriptor(w, h, GraphicsFormat.R32G32B32A32_SFloat, 0);
            RenderingUtils.ReAllocateIfNeeded(ref _SobelRT, rtd, FilterMode.Bilinear);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get(nameof(Sobel_RenderPass));
            Blitter.BlitCameraTexture(cmd, _cameraColorTargetHandle, _SobelRT, _sobel_material, PASS_SobelFilter);
            Blitter.BlitCameraTexture(cmd, _SobelRT, _cameraColorTargetHandle);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            RTHandles.Release(_SobelRT);
        }
    }
}


