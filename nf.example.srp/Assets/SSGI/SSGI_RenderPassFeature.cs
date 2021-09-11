using System;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class SSGI_RenderPassFeature : ScriptableRendererFeature
{
    public enum E_DEBUG
    {
        NONE,
        GI_ONLY,
        GI_BLUR_ONLY,
        GI_FINAL_WITHOUT_BLUR,
        GI_FINAL_WITH_BLUR,
    }

    [Serializable]
    public class SSGI_RenderPassSettings
    {
        public Material MaterialAmbientOcclusion;
        public Material MaterialDualFilter;
        public E_DEBUG DebugMode;
    }

    class SSGI_RenderPass : ScriptableRenderPass
    {
        const string RENDER_TAG = nameof(SSGI_RenderPass);
        
        const int PASS_SSGI_CALCUATE_OCULUSSION = 0;
        const int PASS_SSGI_COMBINE = 1;

        const int PASS_DUALFILTER_DOWN = 0;
        const int PASS_DUALFILTER_UP = 1;

        readonly static int _TmpCopyTex = Shader.PropertyToID("_TmpCopyTex");
        readonly static int _AmbientOcclusionTex = Shader.PropertyToID("_AmbientOcclusionTex");
        readonly static int[] _DualFilterTexs = new int[2]{
            Shader.PropertyToID("_DualFilterTex0"),
            Shader.PropertyToID("_DualFilterTex1"),
        };

        SSGI_RenderPassSettings _settings;
        Material _materialAmbientOcclusion;
        Material _materialDualFilter;
        RenderTargetIdentifier _source;


        public SSGI_RenderPass(SSGI_RenderPassSettings settings)
        {
            _settings = settings;

            _materialAmbientOcclusion = settings.MaterialAmbientOcclusion;

            _materialDualFilter = settings.MaterialDualFilter;
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            ConfigureInput(ScriptableRenderPassInput.Normal);
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            this._source = renderingData.cameraData.renderer.cameraColorTarget;

            var description = renderingData.cameraData.cameraTargetDescriptor;
            var width = description.width;
            var height = description.height;

            cmd.GetTemporaryRT(_TmpCopyTex, description);
            cmd.GetTemporaryRT(_AmbientOcclusionTex, width / 4, height / 4, 0, FilterMode.Bilinear, GraphicsFormat.R16G16B16A16_SFloat);

            int dualFilterW = width / 8;
            int dualFilterH = height / 8;
            for (int i = 0; i < _DualFilterTexs.Length; ++i)
            {
                cmd.GetTemporaryRT(_DualFilterTexs[i], dualFilterW, dualFilterH, 0, FilterMode.Bilinear, GraphicsFormat.R16G16B16A16_SFloat);
                dualFilterW /= 2;
                dualFilterH /= 2;
            }
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(_AmbientOcclusionTex);
            cmd.ReleaseTemporaryRT(_TmpCopyTex);
            for (int i = 0; i < _DualFilterTexs.Length; ++i)
            {
                cmd.ReleaseTemporaryRT(_DualFilterTexs[i]);
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

            cmd.CopyTexture(_source, _TmpCopyTex);
            cmd.Blit(_source, _AmbientOcclusionTex, _materialAmbientOcclusion, PASS_SSGI_CALCUATE_OCULUSSION);

            if (_settings.DebugMode == E_DEBUG.GI_ONLY)
            {
                cmd.Blit(_AmbientOcclusionTex, _source);
            }
            else if (_settings.DebugMode == E_DEBUG.GI_BLUR_ONLY || _settings.DebugMode == E_DEBUG.GI_FINAL_WITH_BLUR)
            {

                cmd.Blit(_AmbientOcclusionTex, _DualFilterTexs[0], _materialDualFilter, PASS_DUALFILTER_DOWN);
                for (int i = 0; i < _DualFilterTexs.Length - 1; ++i)
                {
                    cmd.Blit(_DualFilterTexs[i], _DualFilterTexs[i + 1], _materialDualFilter, PASS_DUALFILTER_DOWN);
                }
                for (int i = _DualFilterTexs.Length - 1; i > 0; --i)
                {
                    cmd.Blit(_DualFilterTexs[i], _DualFilterTexs[i - 1], _materialDualFilter, PASS_DUALFILTER_UP);
                }
                cmd.Blit(_DualFilterTexs[0], _AmbientOcclusionTex, _materialDualFilter, PASS_DUALFILTER_UP);

                if (_settings.DebugMode == E_DEBUG.GI_BLUR_ONLY)
                {
                    cmd.Blit(_AmbientOcclusionTex, _source);
                }
                else
                {
                    cmd.Blit(_TmpCopyTex, _source, _materialAmbientOcclusion, PASS_SSGI_COMBINE);
                }
            }
            else if (_settings.DebugMode == E_DEBUG.GI_FINAL_WITHOUT_BLUR)
            {
                cmd.Blit(_TmpCopyTex, _source, _materialAmbientOcclusion, PASS_SSGI_COMBINE);
            }

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }

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
        renderer.EnqueuePass(_pass);
    }
}
