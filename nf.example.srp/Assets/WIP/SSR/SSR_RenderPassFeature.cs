using System;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;

public class SSR_RenderPassFeature : ScriptableRendererFeature
{
    [SerializeField]
    private SSR_RenderPassSettings _settings = null;
    private SSR_RenderPass _pass;

    public override void Create()
    {
        _pass = new SSR_RenderPass(_settings);
        _pass.renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(_pass);
    }


    // ========================================================================================================================================
    [Serializable]
    public class SSR_RenderPassSettings
    {
        [Range(0, 64)] public int _MaxIteration = 64;
        [Range(0f, 2000f)] public float _MinDistance = 0.4f;
        [Range(0f, 2000f)] public float _MaxDistance = 12;
        [Range(0f, 100f)] public float _MaxThickness = 0.2f;
        public E_DEBUG DebugMode;
    }

    public enum E_DEBUG
    {
        NONE,
        SSR_ONLY,
        SSR_BLUR_ONLY,
        SSR_FINAL_WITHOUT_BLUR,
        SSR_FINAL_WITH_BLUR,
    }


    // ========================================================================================================================================
    private class PassData
    {
        public TextureHandle Tex_ActivateColor;
        public TextureHandle Tex_Normal;
        public TextureHandle Tex_TmpCopy;
        public TextureHandle Tex_SSR;
        public TextureHandle[] Tex_DualFilters;
        public Material Mat_DualFilter;
        public Material Mat_SSR;
        public SSR_RenderPassSettings Settings;
    }


    // ========================================================================================================================================
    private class SSR_RenderPass : ScriptableRenderPass
    {
        private const string RENDER_TAG = nameof(SSR_RenderPass);

        private const int PASS_SSR_CALCUATE_REFLECTION = 0;
        private const int PASS_SSR_COMBINE = 1;

        private const int PASS_DUALFILTER_DOWN = 0;
        private const int PASS_DUALFILTER_UP = 1;

        private readonly static int _SsrTex_Id = Shader.PropertyToID("_SsrTex");

        private SSR_RenderPassSettings _settings;
        private Material _material_SSR;
        private Material _material_DualFilter;


        public SSR_RenderPass(SSR_RenderPassSettings settings)
        {
            _settings = settings;

            if (_material_SSR == null)
            {
                _material_SSR = CoreUtils.CreateEngineMaterial("srp/SSR");
            }
            if (_material_DualFilter == null)
            {
                _material_DualFilter = CoreUtils.CreateEngineMaterial("srp/DualFilter");
            }
        }

        public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
        {
            string passName = "Unsafe Pass";

            UniversalResourceData resourceData = frameData.Get<UniversalResourceData>();

            using (IUnsafeRenderGraphBuilder builder = renderGraph.AddUnsafePass(passName, out PassData passData))
            {
                ConfigureInput(ScriptableRenderPassInput.Normal);

                SetupPassData(renderGraph, frameData, passData);

                builder.UseTexture(passData.Tex_ActivateColor, AccessFlags.ReadWrite);
                builder.UseTexture(passData.Tex_TmpCopy, AccessFlags.ReadWrite);
                builder.UseTexture(passData.Tex_SSR, AccessFlags.ReadWrite);
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
            passData.Tex_SSR = renderGraph.CreateTexture(td2);


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
            passData.Mat_SSR = _material_SSR;
            _material_SSR.SetInt("_MaxIteration", _settings._MaxIteration);
            _material_SSR.SetFloat("_MinDistance", _settings._MinDistance);
            _material_SSR.SetFloat("_MaxDistance", _settings._MaxDistance);
            _material_SSR.SetFloat("_MaxThickness", _settings._MaxThickness);
            passData.Mat_DualFilter = _material_DualFilter;
            passData.Settings = _settings;
        }

        private static void ExecutePass(PassData data, UnsafeGraphContext context)
        {
            if (data.Settings.DebugMode == E_DEBUG.NONE)
            {
                return;
            }

            UnsafeCommandBuffer cmd = context.cmd;
            CommandBuffer nativeCmd = CommandBufferHelpers.GetNativeCommandBuffer(cmd);

            Blitter.BlitCameraTexture(nativeCmd, data.Tex_ActivateColor, data.Tex_TmpCopy);

            nativeCmd.SetGlobalTexture("_MainTex", data.Tex_Normal);
            nativeCmd.SetGlobalTexture("_CameraNormalsTexture", data.Tex_Normal);
            nativeCmd.SetGlobalTexture(_SsrTex_Id, data.Tex_SSR);
            nativeCmd.Blit(data.Tex_ActivateColor, data.Tex_SSR, data.Mat_SSR, PASS_SSR_CALCUATE_REFLECTION);

            if (data.Settings.DebugMode == E_DEBUG.SSR_ONLY)
            {
                Blitter.BlitCameraTexture(nativeCmd, data.Tex_SSR, data.Tex_ActivateColor);
            }
            else if (data.Settings.DebugMode == E_DEBUG.SSR_BLUR_ONLY || data.Settings.DebugMode == E_DEBUG.SSR_FINAL_WITH_BLUR)
            {
                nativeCmd.Blit(data.Tex_SSR, data.Tex_DualFilters[0], data.Mat_DualFilter, PASS_DUALFILTER_DOWN);
                for (int i = 0; i < data.Tex_DualFilters.Length - 1; ++i)
                {
                    nativeCmd.Blit(data.Tex_DualFilters[i], data.Tex_DualFilters[i + 1], data.Mat_DualFilter, PASS_DUALFILTER_DOWN);
                }
                for (int i = data.Tex_DualFilters.Length - 1; i > 0; --i)
                {
                    nativeCmd.Blit(data.Tex_DualFilters[i], data.Tex_DualFilters[i - 1], data.Mat_DualFilter, PASS_DUALFILTER_UP);
                }
                nativeCmd.Blit(data.Tex_DualFilters[0], data.Tex_SSR, data.Mat_DualFilter, PASS_DUALFILTER_UP);

                if (data.Settings.DebugMode == E_DEBUG.SSR_BLUR_ONLY)
                {
                    nativeCmd.Blit(data.Tex_SSR, data.Tex_ActivateColor);
                }
                else
                {
                    nativeCmd.Blit(data.Tex_TmpCopy, data.Tex_ActivateColor, data.Mat_SSR, PASS_SSR_COMBINE);
                }
            }
            else if (data.Settings.DebugMode == E_DEBUG.SSR_FINAL_WITHOUT_BLUR)
            {
                nativeCmd.Blit(data.Tex_TmpCopy, data.Tex_ActivateColor, data.Mat_SSR, PASS_SSR_COMBINE);
            }
        }
    }
}
