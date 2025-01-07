using System;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;

public class SSAO_RenderPassFeature : ScriptableRendererFeature
{
    [SerializeField]
    private SSAO_RenderPassSettings _settings = null;
    private SSAO_RenderPass _pass;

    public override void Create()
    {
        _pass = new SSAO_RenderPass(_settings);
        _pass.renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType != CameraType.Game)
        {
            return;
        }
        renderer.EnqueuePass(_pass);
    }


    // ========================================================================================================================================
    [Serializable]
    public class SSAO_RenderPassSettings
    {
        public Material MaterialAmbientOcclusion;
        public Material MaterialDualFilter;
        public E_DEBUG DebugMode;
    }

    public enum E_DEBUG
    {
        NONE,
        AO_ONLY,
        AO_BLUR_ONLY,
        AO_FINAL_WITHOUT_BLUR,
        AO_FINAL_WITH_BLUR,
    }


    // ========================================================================================================================================
    private class PassData
    {
        public TextureHandle Tex_ActivateColor;
        public TextureHandle Tex_Normal;
        public TextureHandle Tex_TmpCopy;
        public TextureHandle Tex_AmbientOcclusion;
        public TextureHandle[] Tex_DualFilters;
        public Material Mat_DualFilter;
        public Material Mat_AmbientOcclusion;
        public SSAO_RenderPassSettings Settings;

    }

    // ========================================================================================================================================
    private class SSAO_RenderPass : ScriptableRenderPass
    {
        private const string RENDER_TAG = nameof(SSAO_RenderPass);

        private const int PASS_SSAO_CALCUATE_OCULUSSION = 0;
        private const int PASS_SSAO_COMBINE = 1;

        private const int PASS_DUALFILTER_DOWN = 0;
        private const int PASS_DUALFILTER_UP = 1;

        private static readonly int _AmbientOcclusionTex = Shader.PropertyToID("_AmbientOcclusionTex");

        private SSAO_RenderPassSettings _settings;
        private Material _materialAmbientOcclusion;
        private Material _materialDualFilter;


        public SSAO_RenderPass(SSAO_RenderPassSettings settings)
        {
            _settings = settings;

            _materialAmbientOcclusion = settings.MaterialAmbientOcclusion;

            _materialDualFilter = settings.MaterialDualFilter;
        }

        public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
        {
            if (_settings.DebugMode == E_DEBUG.NONE)
            {
                return;
            }

            string passName = "Unsafe Pass";

            UniversalResourceData resourceData = frameData.Get<UniversalResourceData>();

            using (IUnsafeRenderGraphBuilder builder = renderGraph.AddUnsafePass(passName, out PassData passData))
            {
                ConfigureInput(ScriptableRenderPassInput.Normal);

                SetupPassData(renderGraph, frameData, passData);

                builder.UseTexture(passData.Tex_ActivateColor, AccessFlags.ReadWrite);
                builder.UseTexture(passData.Tex_TmpCopy, AccessFlags.ReadWrite);
                builder.UseTexture(passData.Tex_AmbientOcclusion, AccessFlags.ReadWrite);
                builder.UseTexture(passData.Tex_Normal);
                for (int i = 0; i < passData.Tex_DualFilters.Length; ++i)
                {
                    builder.UseTexture(passData.Tex_DualFilters[i], AccessFlags.ReadWrite);
                }
                builder.AllowPassCulling(value: false);
                builder.SetRenderFunc<PassData>(ExecutePass);
            }
        }

        private void SetupPassData(RenderGraph renderGraph, ContextContainer frameData, PassData passData)
        {
            UniversalCameraData cameraData = frameData.Get<UniversalCameraData>();
            UniversalResourceData resourceData = frameData.Get<UniversalResourceData>();

            TextureDesc td1 = renderGraph.GetTextureDesc(resourceData.activeColorTexture);
            passData.Tex_ActivateColor = resourceData.activeColorTexture;
            passData.Tex_Normal = resourceData.cameraNormalsTexture;
            passData.Tex_TmpCopy = renderGraph.CreateTexture(td1);

            TextureDesc td2 = td1;
            td2.width /= 4;
            td2.height /= 4;
            td2.format = GraphicsFormat.R16G16B16A16_SFloat;
            td2.filterMode = FilterMode.Bilinear;
            passData.Tex_AmbientOcclusion = renderGraph.CreateTexture(td2);


            TextureDesc td3 = td1;
            td3.width /= 8;
            td3.height /= 8;
            td3.format = GraphicsFormat.R16G16B16A16_SFloat;
            TextureHandle[] Tex_DualFilters = new TextureHandle[2];
            for (int i = 0; i < Tex_DualFilters.Length; ++i)
            {
                Tex_DualFilters[i] = renderGraph.CreateTexture(td3);
                td3.width /= 2;
                td3.height /= 2;
            }
            passData.Tex_DualFilters = Tex_DualFilters;
            passData.Mat_AmbientOcclusion = _materialAmbientOcclusion;
            passData.Mat_DualFilter = _materialDualFilter;
            passData.Settings = _settings;
        }


        private static void ExecutePass(PassData data, UnsafeGraphContext context)
        {
            UnsafeCommandBuffer cmd = context.cmd;
            CommandBuffer nativeCmd = CommandBufferHelpers.GetNativeCommandBuffer(cmd);

            Blitter.BlitCameraTexture(nativeCmd, data.Tex_ActivateColor, data.Tex_TmpCopy);

            nativeCmd.SetGlobalTexture("_CameraNormalsTexture", data.Tex_Normal);
            Blitter.BlitCameraTexture(nativeCmd, data.Tex_ActivateColor, data.Tex_AmbientOcclusion, data.Mat_AmbientOcclusion, PASS_SSAO_CALCUATE_OCULUSSION);
            nativeCmd.SetGlobalTexture(_AmbientOcclusionTex, data.Tex_AmbientOcclusion);

            if (data.Settings.DebugMode == E_DEBUG.AO_ONLY)
            {
                Blitter.BlitCameraTexture(nativeCmd, data.Tex_AmbientOcclusion, data.Tex_ActivateColor);
            }
            else if (data.Settings.DebugMode == E_DEBUG.AO_BLUR_ONLY || data.Settings.DebugMode == E_DEBUG.AO_FINAL_WITH_BLUR)
            {
                Blitter.BlitCameraTexture(nativeCmd, data.Tex_AmbientOcclusion, data.Tex_DualFilters[0], data.Mat_DualFilter, PASS_DUALFILTER_DOWN);
                for (int i = 0; i < data.Tex_DualFilters.Length - 1; ++i)
                {
                    Blitter.BlitCameraTexture(nativeCmd, data.Tex_DualFilters[i], data.Tex_DualFilters[i + 1], data.Mat_DualFilter, PASS_DUALFILTER_DOWN);
                }
                for (int i = data.Tex_DualFilters.Length - 1; i > 0; --i)
                {
                    Blitter.BlitCameraTexture(nativeCmd, data.Tex_DualFilters[i], data.Tex_DualFilters[i - 1], data.Mat_DualFilter, PASS_DUALFILTER_UP);
                }
                Blitter.BlitCameraTexture(nativeCmd, data.Tex_DualFilters[0], data.Tex_AmbientOcclusion, data.Mat_DualFilter, PASS_DUALFILTER_UP);

                if (data.Settings.DebugMode == E_DEBUG.AO_BLUR_ONLY)
                {
                    Blitter.BlitCameraTexture(nativeCmd, data.Tex_AmbientOcclusion, data.Tex_ActivateColor);
                }
                else
                {
                    Blitter.BlitCameraTexture(nativeCmd, data.Tex_TmpCopy, data.Tex_ActivateColor, data.Mat_AmbientOcclusion, PASS_SSAO_COMBINE);
                }
            }
            else if (data.Settings.DebugMode == E_DEBUG.AO_FINAL_WITHOUT_BLUR)
            {
                Blitter.BlitCameraTexture(nativeCmd, data.Tex_TmpCopy, data.Tex_ActivateColor, data.Mat_AmbientOcclusion, PASS_SSAO_COMBINE);
            }
        }
    }
}
