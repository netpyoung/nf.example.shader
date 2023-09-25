using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class BloomDualFilter_RenderPassFeature : ScriptableRendererFeature
{
    private Pass_BloomDualFilter _pass;
    public Material MaterialBloom;
    public Material MaterialDualFilter;
    public int DualFilterStep;

    private RTCollection _rtCollection;

    protected override void Dispose(bool disposing)
    {
        _rtCollection.Dispose();
    }

    public override void Create()
    {
        DualFilterStep = Math.Max(DualFilterStep, 0);

        _rtCollection = new RTCollection(DualFilterStep);
        _pass = new Pass_BloomDualFilter(_rtCollection, MaterialBloom, MaterialDualFilter);
        _pass.renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType == CameraType.Game)
        {
            _rtCollection.Setup(renderingData.cameraData.cameraTargetDescriptor);
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
    class RTCollection : IDisposable
    {
        public readonly int _BloomNonBlurTex_Id = Shader.PropertyToID("_BloomNonBlurTex");
        public readonly int _BloomBlurTex_Id = Shader.PropertyToID("_BloomBlurTex");

        public RTHandle BloomBrightRT => _bloomBrightRT;
        public RTHandle[] DualFilterRTs => _dualFilterRTs;
        public int DualFilterStep { get; private set; }

        private RTHandle _bloomBrightRT;
        private RTHandle[] _dualFilterRTs;
        private bool _isInitialized;

        public RTCollection(int desireDualFilterStep)
        {
            DualFilterStep = desireDualFilterStep;
        }

        internal void Setup(RenderTextureDescriptor mainDesc)
        {
            if (_isInitialized)
            {
                return;
            }
            _isInitialized = true;

            RenderTextureFormat tf = RenderTextureFormat.ARGB32;
            RenderTextureDescriptor rtdesc = new RenderTextureDescriptor(mainDesc.width, mainDesc.height, tf, 0);

            RenderingUtils.ReAllocateIfNeeded(ref _bloomBrightRT, rtdesc, FilterMode.Bilinear, TextureWrapMode.Clamp,
                name: "_MyColorTexture");

            int fromDiv = 2;
            int measureStep = _MeasureStep(mainDesc.width / fromDiv, mainDesc.height / fromDiv);
            DualFilterStep = Math.Min(measureStep, DualFilterStep);
            _dualFilterRTs = new RTHandle[DualFilterStep];

            for (int i = 0; i < DualFilterStep; ++i)
            {
                int div = 1 << i; // 1, 2, 4, 8 ...
                div = div * fromDiv; // 8, 16, 32, 64 ...
                int w = mainDesc.width / div;
                int h = mainDesc.height / div;
                RenderTextureDescriptor desc = new RenderTextureDescriptor(w, h, tf, 0);
                RenderingUtils.ReAllocateIfNeeded(ref _dualFilterRTs[i], desc, FilterMode.Bilinear, TextureWrapMode.Clamp,
                                name: $"_dualFilterRTs_{i}");
            }
        }

        int _MeasureStep(int width, int height)
        {
            int min = Math.Min(width, height);
            int step = 0;
            while (min > 1)
            {
                min >>= 1;
                step++;
            }
            step++;
            return step;
        }

        public void Dispose()
        {
            if (!_isInitialized)
            {
                return;
            }

            RTHandles.Release(_bloomBrightRT);
            for (int i = 0; i < DualFilterStep; ++i)
            {
                RTHandles.Release(_dualFilterRTs[i]);
            }
        }
    }

    // ====================================================================
    // ====================================================================
    class Pass_BloomDualFilter : ScriptableRenderPass
    {
        const string RENDER_TAG = nameof(Pass_BloomDualFilter);
        const int BLOOM_THRESHOLD_PASS = 0;
        const int BLOOM_COMBINE_PASS = 1;
        const int DUALFILTER_DOWN_PASS = 0;
        const int DUALFILTER_UP_PASS = 1;

        private Material _materialBloom;
        private Material _materialDualFilter;

        private RTHandle _cameraColorTargetHandle;
        private RTCollection _rtc;

        public Pass_BloomDualFilter(RTCollection rtCollection, Material materialBloom, Material materialDualFilter)
        {
            _rtc = rtCollection;
            _materialBloom = materialBloom;
            _materialDualFilter = materialDualFilter;
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

            if (_materialBloom == null)
            {
                return;
            }

            if (_materialDualFilter == null)
            {
                return;
            }

            if (!renderingData.cameraData.postProcessEnabled)
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
            if (_rtc.DualFilterStep < 1)
            {
                return;
            }

            Blitter.BlitCameraTexture(cmd, _cameraColorTargetHandle, _rtc.BloomBrightRT, _materialBloom, BLOOM_THRESHOLD_PASS);
            Blitter.BlitCameraTexture(cmd, _rtc.BloomBrightRT, _rtc.DualFilterRTs[0], _materialDualFilter, DUALFILTER_DOWN_PASS);

            for (int i = 0; i < _rtc.DualFilterStep / 2 - 1; ++i)
            {
                Blitter.BlitCameraTexture(cmd, _rtc.DualFilterRTs[i], _rtc.DualFilterRTs[i + 1], _materialDualFilter, DUALFILTER_DOWN_PASS);
            }
            for (int i = _rtc.DualFilterStep / 2 - 1; i > 0; --i)
            {
                Blitter.BlitCameraTexture(cmd, _rtc.DualFilterRTs[i], _rtc.DualFilterRTs[i - 1], _materialDualFilter, DUALFILTER_UP_PASS);
            }

            //Blitter.BlitCameraTexture(cmd, _bloomBrightRT, _dualFilterDownRT, _materialDualFilter, DUALFILTER_DOWN_PASS);
            //Blitter.BlitCameraTexture(cmd, _dualFilterDownRT, _dualFilterUpRT, _materialDualFilter, DUALFILTER_UP_PASS);

            cmd.SetGlobalTexture(_rtc._BloomNonBlurTex_Id, _rtc.BloomBrightRT);
            cmd.SetGlobalTexture(_rtc._BloomBlurTex_Id, _rtc.DualFilterRTs[0]);

            Blitter.BlitCameraTexture(cmd, _cameraColorTargetHandle, _cameraColorTargetHandle, _materialBloom, BLOOM_COMBINE_PASS);
        }
    }
}
