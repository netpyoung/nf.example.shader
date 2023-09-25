using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering.Universal;

public class Brightness_RenderPassFeature : ScriptableRendererFeature
{
    [SerializeField]
    Brightness_RenderPassSettings _settings = new Brightness_RenderPassSettings();
    Brightness_RenderPass _pass;

    public override void Create()
    {
        _pass = new Brightness_RenderPass(_settings);
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
            _pass.Setup(renderer.cameraColorTargetHandle, renderingData.cameraData.cameraTargetDescriptor);
        }
    }
    // ====================================================================
    // ====================================================================
    [Serializable]
    public struct Brightness_RenderPassSettings
    {
        public float _AdaptionConstant;
        public float _Key;
    }

    // ====================================================================
    // ====================================================================
    class RTCollection : IDisposable
    {
        public readonly int _TmpCurrMipmapTex = Shader.PropertyToID("_TmpCurrMipmapTex");
        public readonly int _TmpCopyTex = Shader.PropertyToID("_TmpCopyTex");
        public readonly int _LumaCurrTex = Shader.PropertyToID("_LumaCurrTex");
        public readonly int _LumaAdaptPrevTex = Shader.PropertyToID("_LumaAdaptPrevTex");
        public readonly int _LumaAdaptCurrTex = Shader.PropertyToID("_LumaAdaptCurrTex");

        private RTHandle _lumaPrevRT;
        public RTHandle _LumaPrevRT => _lumaPrevRT;
        private RTHandle _lumaCurrRT;
        public RTHandle _LumaCurrRT => _lumaCurrRT;
        private RTHandle _lumaAdaptCurrRT;
        public RTHandle _LumaAdaptCurrRT => _lumaAdaptCurrRT;
        private RTHandle _tmpCurrMipmapRT;
        public RTHandle _TmpCurrMipmapRT => _tmpCurrMipmapRT;
        private RTHandle _tmpCopyRT;
        public RTHandle _TmpCopyRT => _tmpCopyRT;

        private bool _isInitialized;

        internal void Setup(RenderTextureDescriptor mainDesc)
        {
            if (_isInitialized)
            {
                return;
            }
            _isInitialized = true;

            RenderTextureDescriptor rtdesc = new RenderTextureDescriptor(1, 1, GraphicsFormat.R16G16_SFloat, 0, 0);
            RenderingUtils.ReAllocateIfNeeded(ref _lumaPrevRT, rtdesc, FilterMode.Bilinear, TextureWrapMode.Clamp,
                name: "_lumaPrevRT");
            RenderingUtils.ReAllocateIfNeeded(ref _lumaCurrRT, rtdesc, FilterMode.Bilinear, TextureWrapMode.Clamp,
                name: "_lumaCurrRT");
            RenderingUtils.ReAllocateIfNeeded(ref _lumaAdaptCurrRT, rtdesc, FilterMode.Bilinear, TextureWrapMode.Clamp,
                name: "_lumaAdaptCurrRT");

            int w = mainDesc.width;
            int h = mainDesc.height;
            w = ToPow2RoundUp(w / 2);
            h = ToPow2RoundUp(h / 2);
            RenderTextureDescriptor rtdesc2 = new RenderTextureDescriptor(w, h, GraphicsFormat.R16G16_SFloat, 0)
            {
                autoGenerateMips = true,
                useMipMap = true
            };
            RenderingUtils.ReAllocateIfNeeded(ref _tmpCurrMipmapRT, rtdesc2, FilterMode.Bilinear, TextureWrapMode.Clamp,
                name: "_tmpCurrMipmapRT");

            RenderTextureDescriptor rtdesc3 = new RenderTextureDescriptor(mainDesc.width, mainDesc.height, GraphicsFormat.R32G32B32A32_SFloat, 0);
            RenderingUtils.ReAllocateIfNeeded(ref _tmpCopyRT, rtdesc3, FilterMode.Bilinear, TextureWrapMode.Clamp,
                name: "_tmpCopyRT");
        }

        public void Dispose()
        {
            if (!_isInitialized)
            {
                return;
            }

            RTHandles.Release(_lumaPrevRT);
            RTHandles.Release(_lumaCurrRT);
            RTHandles.Release(_lumaAdaptCurrRT);
            RTHandles.Release(_tmpCurrMipmapRT);
            RTHandles.Release(_tmpCopyRT);
        }


        public static int ToPow2RoundUp(int x)
        {
            if (x == 0)
            {
                return 0;
            }
            return MakeMSB(x - 1) + 1;
        }

        public static int MakeMSB(int x)
        {
            x |= x >> 1;
            x |= x >> 2;
            x |= x >> 4;
            x |= x >> 8;
            x |= x >> 16;
            return x;
        }
    }

    // ====================================================================
    // ====================================================================
    class Brightness_RenderPass : ScriptableRenderPass
    {
        private Brightness_RenderPassSettings _settings;

        const int PASS_Brightness_CalcuateLuma = 0;
        const int PASS_Brightness_CopyLuma = 1;
        const int PASS_Brightness_AdaptedFilter = 2;
        const int PASS_EyeAdaptation_ToneMapping = 0;

        private RTHandle _cameraColorTargetHandle;
        private Material _mat_Brightness;
        private Material _mat_EyeAdaptation;
        private RTCollection _rtc = new RTCollection();

        public Brightness_RenderPass(Brightness_RenderPassSettings settings)
        {
            _settings = settings;
            if (_mat_Brightness == null)
            {
                _mat_Brightness = CoreUtils.CreateEngineMaterial("Hidden/Brightness");
            }
            if (_mat_EyeAdaptation == null)
            {
                _mat_EyeAdaptation = CoreUtils.CreateEngineMaterial("Hidden/EyeAdaptation");
            }
            _mat_Brightness.SetFloat("_AdaptionConstant", settings._AdaptionConstant);
            _mat_EyeAdaptation.SetFloat("_Key", settings._Key);
        }

        internal void Setup(RTHandle cameraColorTargetHandle, RenderTextureDescriptor rtd)
        {
            _rtc.Setup(rtd);
            _cameraColorTargetHandle = cameraColorTargetHandle;
        }

        ~Brightness_RenderPass()
        {
            _rtc.Dispose();
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CameraData cameraData = renderingData.cameraData;
            if (cameraData.camera.cameraType != CameraType.Game)
            {
                return;
            }

            CommandBuffer cmd = CommandBufferPool.Get(nameof(Brightness_RenderPass));
            cmd.SetGlobalTexture(_rtc._LumaAdaptPrevTex, _rtc._LumaPrevRT);
            cmd.SetGlobalTexture(_rtc._LumaCurrTex, _rtc._LumaCurrRT);
            cmd.SetGlobalTexture(_rtc._LumaAdaptCurrTex, _rtc._LumaAdaptCurrRT);
            cmd.SetGlobalTexture(_rtc._TmpCurrMipmapTex, _rtc._TmpCurrMipmapRT);

            Blitter.BlitCameraTexture(cmd, _cameraColorTargetHandle, _rtc._TmpCopyRT);

            Blitter.BlitCameraTexture(cmd, _cameraColorTargetHandle, _rtc._TmpCurrMipmapRT, _mat_Brightness, PASS_Brightness_CalcuateLuma);
            Blitter.BlitCameraTexture(cmd, _rtc._TmpCurrMipmapRT, _rtc._LumaCurrRT, _mat_Brightness, PASS_Brightness_CopyLuma);

            Blitter.BlitCameraTexture(cmd, _rtc._LumaCurrRT, _rtc._LumaAdaptCurrRT, _mat_Brightness, PASS_Brightness_AdaptedFilter);
            Blitter.BlitCameraTexture(cmd, _rtc._TmpCopyRT, _cameraColorTargetHandle, _mat_EyeAdaptation, PASS_EyeAdaptation_ToneMapping);

            Blitter.BlitCameraTexture(cmd, _rtc._LumaAdaptCurrRT, _rtc._LumaPrevRT);

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }
}


