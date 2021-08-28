using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class FXAA_RenderPassFeature : ScriptableRendererFeature
{

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

    class FXAA_RenderPass : ScriptableRenderPass
    {
        FXAA_RenderPassSettings _settings;
        readonly static int _LuminanceConversionTex = Shader.PropertyToID("_LuminanceConversionTex");
        const int PASS_FXAA_LUMINANCE_CONVERSION = 0;
        const int PASS_FXAA_APPLY = 1;

        RenderTargetIdentifier RTID = new RenderTargetIdentifier(_LuminanceConversionTex);
        RenderTargetIdentifier _colorBuffer;
        Material _FXAA_material;
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

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            _colorBuffer = renderingData.cameraData.renderer.cameraColorTarget;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (!_settings.IsEnabled)
            {
                return;
            }
            CommandBuffer cmd = CommandBufferPool.Get(nameof(FXAA_RenderPass));
            int w = renderingData.cameraData.camera.pixelWidth;
            int h = renderingData.cameraData.camera.pixelHeight;
            cmd.GetTemporaryRT(_LuminanceConversionTex, w, h, 0, FilterMode.Bilinear);
            cmd.SetGlobalTexture("_LumaTex", _LuminanceConversionTex);
            Blit(cmd, _colorBuffer, _LuminanceConversionTex, _FXAA_material, PASS_FXAA_LUMINANCE_CONVERSION);
            Blit(cmd, _LuminanceConversionTex, _colorBuffer, _FXAA_material, PASS_FXAA_APPLY);
            cmd.ReleaseTemporaryRT(_LuminanceConversionTex);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
        }
    }

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
        renderer.EnqueuePass(_pass);
    }
}


