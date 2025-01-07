using System;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
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
        if (renderingData.cameraData.cameraType != CameraType.Game)
        {
            return;
        }
        renderer.EnqueuePass(_pass);
    }


    // ========================================================================================================================================
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


    // ========================================================================================================================================
    private class PassData
    {
        public TextureHandle Tex_Src;
        public Material Mat_LuminanceConversion;
    }


    // ========================================================================================================================================
    private class FXAA_RenderPass : ScriptableRenderPass
    {
        private FXAA_RenderPassSettings _settings;
        private const string m_PassName = nameof(FXAA_RenderPass);
        private readonly static int _LuminanceConversionTex = Shader.PropertyToID("_LuminanceConversionTex");
        private const int PASS_FXAA_LUMINANCE_CONVERSION = 0;
        private const int PASS_FXAA_APPLY = 1;

        private Material _FXAA_material;

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
            requiresIntermediateTexture = true;
        }

        public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
        {
            if (!_settings.IsEnabled)
            {
                return;
            }
            UniversalResourceData resourceData = frameData.Get<UniversalResourceData>();

            TextureHandle srcHandle = resourceData.activeColorTexture;
            TextureHandle dstHandle;
            {
                TextureDesc destinationDesc = renderGraph.GetTextureDesc(srcHandle);
                destinationDesc.name = $"CameraColor-{m_PassName}";
                destinationDesc.clearBuffer = false;
                destinationDesc.format = GraphicsFormat.R32G32B32A32_SFloat;
                dstHandle = renderGraph.CreateTexture(destinationDesc);
            }

            using (IRasterRenderGraphBuilder builder = renderGraph.AddRasterRenderPass(m_PassName, out PassData passData))
            {
                passData.Tex_Src = srcHandle;
                passData.Mat_LuminanceConversion = _FXAA_material;

                builder.UseTexture(passData.Tex_Src);
                builder.SetRenderAttachment(dstHandle, index: 0);
                builder.SetRenderFunc<PassData>(ExecutePass1);
            }

            using (IRasterRenderGraphBuilder builder = renderGraph.AddRasterRenderPass(m_PassName, out PassData passData))
            {
                passData.Tex_Src = dstHandle;
                passData.Mat_LuminanceConversion = _FXAA_material;

                builder.UseTexture(passData.Tex_Src);
                builder.SetRenderAttachment(srcHandle, index: 0);
                builder.SetRenderFunc<PassData>(ExecutePass2);
            }
        }

        private static void ExecutePass1(PassData data, RasterGraphContext rgContext)
        {
            Vector4 scaleBias = new Vector4(1, 1, 0, 0);
            Blitter.BlitTexture(rgContext.cmd, data.Tex_Src, scaleBias, data.Mat_LuminanceConversion, pass: PASS_FXAA_LUMINANCE_CONVERSION);

        }

        private static void ExecutePass2(PassData data, RasterGraphContext rgContext)
        {
            Vector4 scaleBias = new Vector4(1, 1, 0, 0);
            //Blitter.BlitTexture(rgContext.cmd, data.Tex_Src, scaleBias, mipLevel: 0, bilinear: false);
            Blitter.BlitTexture(rgContext.cmd, data.Tex_Src, scaleBias, data.Mat_LuminanceConversion, pass: PASS_FXAA_APPLY);
        }
    }
}


