using System;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class Uber_RenderPassFeature : ScriptableRendererFeature
{
    [SerializeField]
    Uber_RenderPassSettings _settings = null;
    Uber_RenderPass _pass;

    public override void Create()
    {
        _pass = new Uber_RenderPass(_settings);
        _pass.renderPassEvent = RenderPassEvent.AfterRendering;
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
    public class Uber_RenderPassSettings
    {
        public bool _UBER_A;
        public bool _UBER_B;
    }

    // ====================================================================
    // ====================================================================
    class Uber_RenderPass : ScriptableRenderPass
    {
        Uber_RenderPassSettings _settings;
        const int PASS_SobelFilter = 0;

        RenderTargetIdentifier _colorBuffer;
        Material _mat_uber;
        private RTHandle _TempRT;
        private RTHandle _cameraColorTargetHandle;

        public Uber_RenderPass(Uber_RenderPassSettings settings)
        {
            _settings = settings;
            if (_mat_uber == null)
            {
                _mat_uber = CoreUtils.CreateEngineMaterial("Hidden/Uber");
            }

            if (settings._UBER_A)
            {
                _mat_uber.EnableKeyword("_UBER_A");
            }
            else
            {
                _mat_uber.DisableKeyword("_UBER_A");
            }

            if (settings._UBER_B)
            {
                _mat_uber.EnableKeyword("_UBER_B");
            }
            else
            {
                _mat_uber.DisableKeyword("_UBER_B");
            }
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
            RenderingUtils.ReAllocateIfNeeded(ref _TempRT, rtd, FilterMode.Bilinear);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get(nameof(Uber_RenderPass));
            Blitter.BlitCameraTexture(cmd, _cameraColorTargetHandle, _TempRT, _mat_uber, PASS_SobelFilter);
            Blitter.BlitCameraTexture(cmd, _TempRT, _cameraColorTargetHandle);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            RTHandles.Release(_TempRT);
        }
    }
}


