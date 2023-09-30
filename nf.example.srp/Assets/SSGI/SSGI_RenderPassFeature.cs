using System;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class SSGI_RenderPassFeature : ScriptableRendererFeature
{

    [SerializeField]
    SSGI_RenderPassSettings _settings = null;
    SSGI_RenderPass _pass;

    public override void Create()
    {
        _pass = new SSGI_RenderPass(_settings);
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
    public enum E_DEBUG
    {
        NONE,
        GI_ONLY,
        GI_BLUR_ONLY,
        GI_FINAL_WITHOUT_BLUR,
        GI_FINAL_WITH_BLUR,
    }

    // ====================================================================
    // ====================================================================
    [Serializable]
    public class SSGI_RenderPassSettings
    {
        public Material MaterialAmbientOcclusion;
        public Material MaterialDualFilter;
        public E_DEBUG DebugMode;
    }

    // ====================================================================
    // ====================================================================
    class SSGI_RenderPass : ScriptableRenderPass
    {
        const string RENDER_TAG = nameof(SSGI_RenderPass);

        const int PASS_SSGI_CALCUATE_OCULUSSION = 0;
        const int PASS_SSGI_COMBINE = 1;

        const int PASS_DUALFILTER_DOWN = 0;
        const int PASS_DUALFILTER_UP = 1;

        private readonly int _AmbientOcclusionTex = Shader.PropertyToID("_AmbientOcclusionTex");
        private RTHandle _TmpCopyRT;
        private RTHandle _AmbientOcclusionRT;
        private RTHandle[] _DualFilterRTs = new RTHandle[2];

        SSGI_RenderPassSettings _settings;
        Material _materialAmbientOcclusion;
        Material _materialDualFilter;
        private RTHandle _cameraColorTargetHandle;

        public SSGI_RenderPass(SSGI_RenderPassSettings settings)
        {
            _settings = settings;

            _materialAmbientOcclusion = settings.MaterialAmbientOcclusion;

            _materialDualFilter = settings.MaterialDualFilter;
        }

        internal void Setup(RTHandle cameraColorTargetHandle)
        {
            _cameraColorTargetHandle = cameraColorTargetHandle;
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            ConfigureInput(ScriptableRenderPassInput.Normal);
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            Camera camera = renderingData.cameraData.camera;
            int width = camera.pixelWidth;
            int height = camera.pixelHeight;
            RenderTextureDescriptor rtd1 = new RenderTextureDescriptor(width, height, GraphicsFormat.R32G32B32A32_SFloat, 0);

            RenderingUtils.ReAllocateIfNeeded(ref _TmpCopyRT, rtd1);
            RenderTextureDescriptor rtd2 = new RenderTextureDescriptor(width / 4, height / 4, GraphicsFormat.R16G16B16A16_SFloat, 0);
            RenderingUtils.ReAllocateIfNeeded(ref _AmbientOcclusionRT, rtd1, FilterMode.Bilinear);


            int dualFilterW = width / 8;
            int dualFilterH = height / 8;
            RenderTextureDescriptor rtd3 = new RenderTextureDescriptor(dualFilterW, dualFilterH, GraphicsFormat.R16G16B16A16_SFloat, 0);
            for (int i = 0; i < _DualFilterRTs.Length; ++i)
            {
                RenderingUtils.ReAllocateIfNeeded(ref _DualFilterRTs[i], rtd3, FilterMode.Bilinear);
                dualFilterW /= 2;
                dualFilterH /= 2;
            }
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            RTHandles.Release(_AmbientOcclusionRT);
            RTHandles.Release(_TmpCopyRT);
            for (int i = 0; i < _DualFilterRTs.Length; ++i)
            {
                RTHandles.Release(_DualFilterRTs[i]);
            }
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.isSceneViewCamera)
            {
                return;
            }

            if (_settings.DebugMode == E_DEBUG.NONE)
            {
                return;
            }

            CommandBuffer cmd = CommandBufferPool.Get(RENDER_TAG);
            cmd.SetGlobalTexture(_AmbientOcclusionTex, _AmbientOcclusionRT);
            Blitter.BlitCameraTexture(cmd, _cameraColorTargetHandle, _TmpCopyRT);
            Blitter.BlitCameraTexture(cmd, _cameraColorTargetHandle, _AmbientOcclusionRT, _materialAmbientOcclusion, PASS_SSGI_CALCUATE_OCULUSSION);

            if (_settings.DebugMode == E_DEBUG.GI_ONLY)
            {
                Blitter.BlitCameraTexture(cmd, _AmbientOcclusionRT, _cameraColorTargetHandle);
            }
            else if (_settings.DebugMode == E_DEBUG.GI_BLUR_ONLY || _settings.DebugMode == E_DEBUG.GI_FINAL_WITH_BLUR)
            {

                Blitter.BlitCameraTexture(cmd, _AmbientOcclusionRT, _DualFilterRTs[0], _materialDualFilter, PASS_DUALFILTER_DOWN);
                for (int i = 0; i < _DualFilterRTs.Length - 1; ++i)
                {
                    Blitter.BlitCameraTexture(cmd, _DualFilterRTs[i], _DualFilterRTs[i + 1], _materialDualFilter, PASS_DUALFILTER_DOWN);
                }
                for (int i = _DualFilterRTs.Length - 1; i > 0; --i)
                {
                    Blitter.BlitCameraTexture(cmd, _DualFilterRTs[i], _DualFilterRTs[i - 1], _materialDualFilter, PASS_DUALFILTER_UP);
                }
                Blitter.BlitCameraTexture(cmd, _DualFilterRTs[0], _AmbientOcclusionRT, _materialDualFilter, PASS_DUALFILTER_UP);

                if (_settings.DebugMode == E_DEBUG.GI_BLUR_ONLY)
                {
                    Blitter.BlitCameraTexture(cmd, _AmbientOcclusionRT, _cameraColorTargetHandle);
                }
                else
                {
                    Blitter.BlitCameraTexture(cmd, _TmpCopyRT, _cameraColorTargetHandle, _materialAmbientOcclusion, PASS_SSGI_COMBINE);
                }
            }
            else if (_settings.DebugMode == E_DEBUG.GI_FINAL_WITHOUT_BLUR)
            {
                Blitter.BlitCameraTexture(cmd, _TmpCopyRT, _cameraColorTargetHandle, _materialAmbientOcclusion, PASS_SSGI_COMBINE);
            }

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }
}
