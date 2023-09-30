using System;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class FXAA_RenderPassFeature : ScriptableRendererFeature
{
    [SerializeField]
    FXAA_RenderPassSettings _settings = null;
    FXAA_RenderPass _pass;

    public override void Create()
    {
        _pass = new FXAA_RenderPass(_settings);
        _pass.renderPassEvent = RenderPassEvent.AfterRenderingPostProcessing;
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
    public class FXAA_RenderPassSettings
    {
        [Range(0.0312f, 0.0833f)]
        public float contrastThreshold = 0.0312f;
        [Range(0.063f, 0.333f)]
        public float relativeThreshold = 0.063f;
        [Range(0f, 1f)]
        public float subpixelBlending = 0.75f;
        public bool IsEnabled;
    }

    // ====================================================================
    // ====================================================================
    private class FXAA_RenderPass : ScriptableRenderPass
    {
        private FXAA_RenderPassSettings _settings;

        private readonly static int _LuminanceConversionTex = Shader.PropertyToID("_LuminanceConversionTex");
        private RTHandle _LuminanceConversionRT;
        private const int PASS_FXAA_LUMINANCE_CONVERSION = 0;
        private const int PASS_FXAA_APPLY = 1;

        private Material _FXAA_material;
        private RTHandle _cameraColorTargetHandle;

        public FXAA_RenderPass(FXAA_RenderPassSettings settings)
        {
            _settings = settings;
            if (_FXAA_material == null)
            {
                _FXAA_material = CoreUtils.CreateEngineMaterial("Hidden/FXAA");
            }

            _FXAA_material.SetFloat("_ContrastThreshold", settings.contrastThreshold);
            _FXAA_material.SetFloat("_RelativeThreshold", settings.relativeThreshold);
            _FXAA_material.SetFloat("_SubpixelBlending", settings.subpixelBlending);
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
            RenderingUtils.ReAllocateIfNeeded(ref _LuminanceConversionRT, rtd, FilterMode.Bilinear);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CameraData cameraData = renderingData.cameraData;
            if (cameraData.camera.cameraType != CameraType.Game)
            {
                return;
            }

            if (!_settings.IsEnabled)
            {
                return;
            }

            CommandBuffer cmd = CommandBufferPool.Get(nameof(FXAA_RenderPass));
            Blitter.BlitCameraTexture(cmd, _cameraColorTargetHandle, _LuminanceConversionRT, _FXAA_material, PASS_FXAA_LUMINANCE_CONVERSION);
            Blitter.BlitCameraTexture(cmd, _LuminanceConversionRT, _cameraColorTargetHandle, _FXAA_material, PASS_FXAA_APPLY);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            RTHandles.Release(_LuminanceConversionRT);
        }
    }
}


