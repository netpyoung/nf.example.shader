using System;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
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

    protected override void Dispose(bool disposing)
    {
        _pass.Dispose();
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType != CameraType.Game)
        {
            return;
        }

        _pass.Setup(renderingData);
        renderer.EnqueuePass(_pass);
    }

    public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType != CameraType.Game)
        {
            return;
        }
        _pass.ConfigureInput(ScriptableRenderPassInput.Color);
    }


    // ====================================================================
    [Serializable]
    public struct Brightness_RenderPassSettings
    {
        public float _AdaptionConstant;
        public float _Key;
    }


    // ====================================================================
    class PassData
    {
        public TextureHandle SrcTexHandle;
        public TextureHandle LumaAdaptPrevTexHandle;
        public TextureHandle LumaAdaptCurrTexHandle;
        public TextureHandle LumaCurrTexHandle;
        public TextureHandle TmpCurrMipmapTexHandle;
        public TextureHandle TmpCopyTexHandle;
        public Material Mat_Brightness;
        public Material Mat_EyeAdaptation;
    }

    // ====================================================================

    class RTCollection : IDisposable
    {
        private RTHandle _lumaPrevRT;
        private RTHandle _lumaCurrRT;
        private RTHandle _lumaAdaptCurrRT;
        private RTHandle _tmpCurrMipmapRT;
        private RTHandle _tmpCopyRT;

        public RTHandle _LumaPrevRT => _lumaPrevRT;
        public RTHandle _LumaCurrRT => _lumaCurrRT;
        public RTHandle _LumaAdaptCurrRT => _lumaAdaptCurrRT;
        public RTHandle _TmpCurrMipmapRT => _tmpCurrMipmapRT;
        public RTHandle _TmpCopyRT => _tmpCopyRT;

        public readonly int _LumaAdaptPrevTex = Shader.PropertyToID("_LumaAdaptPrevTex");
        public readonly int _LumaAdaptCurrTex = Shader.PropertyToID("_LumaAdaptCurrTex");
        public readonly int _LumaCurrTex = Shader.PropertyToID("_LumaCurrTex");

        internal void Setup(RenderTextureDescriptor mainDesc)
        {
            RenderTextureDescriptor rtdesc = new RenderTextureDescriptor(1, 1, GraphicsFormat.R16G16_SFloat, 0, 0);
            RenderingUtils.ReAllocateHandleIfNeeded(ref _lumaPrevRT, rtdesc, FilterMode.Bilinear, TextureWrapMode.Clamp, name: "_lumaPrevRT");
            RenderingUtils.ReAllocateHandleIfNeeded(ref _lumaCurrRT, rtdesc, FilterMode.Bilinear, TextureWrapMode.Clamp, name: "_lumaCurrRT");
            RenderingUtils.ReAllocateHandleIfNeeded(ref _lumaAdaptCurrRT, rtdesc, FilterMode.Bilinear, TextureWrapMode.Clamp, name: "_lumaAdaptCurrRT");

            int w = mainDesc.width;
            int h = mainDesc.height;
            w = ToPow2RoundUp(w / 2);
            h = ToPow2RoundUp(h / 2);
            RenderTextureDescriptor rtdesc2 = new RenderTextureDescriptor(w, h, GraphicsFormat.R16G16_SFloat, 0)
            {
                autoGenerateMips = true,
                useMipMap = true
            };
            RenderingUtils.ReAllocateHandleIfNeeded(ref _tmpCurrMipmapRT, rtdesc2, FilterMode.Bilinear, TextureWrapMode.Clamp, name: "_tmpCurrMipmapRT");

            RenderTextureDescriptor rtdesc3 = new RenderTextureDescriptor(mainDesc.width, mainDesc.height, GraphicsFormat.R32G32B32A32_SFloat, 0);
            RenderingUtils.ReAllocateHandleIfNeeded(ref _tmpCopyRT, rtdesc3, FilterMode.Bilinear, TextureWrapMode.Clamp, name: "_tmpCopyRT");
        }

        public void Dispose()
        {
            RTHandles.Release(_lumaPrevRT);
            RTHandles.Release(_lumaCurrRT);
            RTHandles.Release(_lumaAdaptCurrRT);
            RTHandles.Release(_tmpCurrMipmapRT);
            RTHandles.Release(_tmpCopyRT);
        }

        private static int ToPow2RoundUp(int x)
        {
            if (x == 0)
            {
                return 0;
            }
            return MakeMSB(x - 1) + 1;
        }

        private static int MakeMSB(int x)
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
    class Brightness_RenderPass : ScriptableRenderPass, IDisposable
    {
        const int PASS_Brightness_CalcuateLuma = 0;
        const int PASS_Brightness_CopyLuma = 1;
        const int PASS_Brightness_AdaptedFilter = 2;
        const int PASS_EyeAdaptation_ToneMapping = 0;

        private Material _mat_Brightness;
        private Material _mat_EyeAdaptation;
        private RTCollection _rtc = new RTCollection();

        public Brightness_RenderPass(Brightness_RenderPassSettings settings)
        {
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

        public void Dispose()
        {
            _rtc.Dispose();
        }

        public void Setup(RenderingData renderingData)
        {
            RenderTextureDescriptor desc = renderingData.cameraData.cameraTargetDescriptor;
            _rtc.Setup(desc);
        }

        public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
        {
            string passName = "Unsafe Pass";

            UniversalCameraData cameraData = frameData.Get<UniversalCameraData>();
            if (cameraData.camera.cameraType != CameraType.Game)
            {
                return;
            }

            using (IUnsafeRenderGraphBuilder builder = renderGraph.AddUnsafePass(passName, out PassData passData))
            {
                UniversalResourceData resourceData = frameData.Get<UniversalResourceData>();

                passData.SrcTexHandle = resourceData.activeColorTexture;
                passData.LumaAdaptPrevTexHandle = renderGraph.ImportTexture(_rtc._LumaPrevRT);
                passData.LumaCurrTexHandle = renderGraph.ImportTexture(_rtc._LumaCurrRT);
                passData.LumaAdaptCurrTexHandle = renderGraph.ImportTexture(_rtc._LumaAdaptCurrRT);
                passData.TmpCurrMipmapTexHandle = renderGraph.ImportTexture(_rtc._TmpCurrMipmapRT);
                passData.TmpCopyTexHandle = renderGraph.ImportTexture(_rtc._TmpCopyRT);
                passData.Mat_Brightness = _mat_Brightness;
                passData.Mat_EyeAdaptation = _mat_EyeAdaptation;

                builder.UseTexture(passData.SrcTexHandle);
                builder.AllowPassCulling(value: false);
                builder.SetRenderFunc<PassData>(ExecutePass);
            }
        }

        static void ExecutePass(PassData data, UnsafeGraphContext context)
        {
            UnsafeCommandBuffer cmd = context.cmd;
            CommandBuffer unsafeCmd = CommandBufferHelpers.GetNativeCommandBuffer(context.cmd);

            Vector4 scaleBias = new Vector4(1, 1, 0, 0);

            cmd.SetRenderTarget(data.TmpCopyTexHandle);
            Blitter.BlitTexture(unsafeCmd, data.SrcTexHandle, scaleBias, mipLevel: 0, bilinear: false);

            cmd.SetRenderTarget(data.TmpCurrMipmapTexHandle);
            Blitter.BlitTexture(unsafeCmd, data.SrcTexHandle, scaleBias, data.Mat_Brightness, PASS_Brightness_CalcuateLuma);

            cmd.SetRenderTarget(data.LumaCurrTexHandle);
            Blitter.BlitTexture(unsafeCmd, data.TmpCurrMipmapTexHandle, scaleBias, data.Mat_Brightness, PASS_Brightness_CopyLuma);

            cmd.SetRenderTarget(data.LumaAdaptCurrTexHandle);
            unsafeCmd.SetGlobalTexture(Shader.PropertyToID("_LumaAdaptPrevTex"), data.LumaAdaptPrevTexHandle);
            Blitter.BlitTexture(unsafeCmd, data.LumaCurrTexHandle, scaleBias, data.Mat_Brightness, PASS_Brightness_AdaptedFilter);

            cmd.SetRenderTarget(data.SrcTexHandle);
            unsafeCmd.SetGlobalTexture(Shader.PropertyToID("_LumaAdaptCurrTex"), data.LumaAdaptCurrTexHandle);
            unsafeCmd.SetGlobalTexture(Shader.PropertyToID("_LumaCurrTex"), data.LumaCurrTexHandle);
            Blitter.BlitTexture(unsafeCmd, data.TmpCopyTexHandle, scaleBias, data.Mat_EyeAdaptation, PASS_EyeAdaptation_ToneMapping);

            cmd.SetRenderTarget(data.LumaAdaptPrevTexHandle);
            Blitter.BlitTexture(unsafeCmd, data.LumaAdaptCurrTexHandle, scaleBias, mipLevel: 0, bilinear: false);
        }
    }
}


