using System;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class SSR_RenderPassFeature : ScriptableRendererFeature
{
    public enum E_DEBUG
    {
        NONE,
        SSR_ONLY,
        SSR_BLUR_ONLY,
        SSR_FINAL_WITHOUT_BLUR,
        SSR_FINAL_WITH_BLUR,
    }

    [Serializable]
    public class SSR_RenderPassSettings
    {
        [Range(0, 64)] public int _MaxIteration = 64;
        [Range(0f, 2000f)] public float _MinDistance = 0.4f;
        [Range(0f, 2000f)] public float _MaxDistance = 12;
        [Range(0f, 100f)] public float _MaxThickness = 0.2f;
        public E_DEBUG DebugMode;
    }

    class SSR_RenderPass : ScriptableRenderPass
    {
        const string RENDER_TAG = nameof(SSR_RenderPass);
        
        const int PASS_SSR_CALCUATE_REFLECTION = 0;
        const int PASS_SSR_COMBINE = 1;

        const int PASS_DUALFILTER_DOWN = 0;
        const int PASS_DUALFILTER_UP = 1;

        readonly static int _TmpCopyTex = Shader.PropertyToID("_TmpCopyTex");
        readonly static int _SsrTex = Shader.PropertyToID("_SsrTex");
        readonly static int[] _DualFilterTexs = new int[2]{
            Shader.PropertyToID("_DualFilterTex0"),
            Shader.PropertyToID("_DualFilterTex1"),
        };

        SSR_RenderPassSettings _settings;
        Material _material_SSR;
        Material _material_DualFilter;
        RenderTargetIdentifier _source;


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
            _material_SSR.SetInt("_MaxIteration", settings._MaxIteration);
            _material_SSR.SetFloat("_MinDistance", settings._MinDistance);
            _material_SSR.SetFloat("_MaxDistance", settings._MaxDistance);
            _material_SSR.SetFloat("_MaxThickness", settings._MaxThickness);
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            ConfigureInput(ScriptableRenderPassInput.Normal);
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            ref CameraData cameraData = ref renderingData.cameraData;

            this._source = cameraData.renderer.cameraColorTarget;

            var description = cameraData.cameraTargetDescriptor;
            var width = description.width;
            var height = description.height;

            cmd.GetTemporaryRT(_TmpCopyTex, description);
            cmd.GetTemporaryRT(_SsrTex, width / 4, height / 4, 0, FilterMode.Bilinear, GraphicsFormat.R16G16B16A16_SFloat);

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
            cmd.ReleaseTemporaryRT(_SsrTex);
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
            cmd.Blit(_source, _SsrTex, _material_SSR, PASS_SSR_CALCUATE_REFLECTION);

            if (_settings.DebugMode == E_DEBUG.SSR_ONLY)
            {
                cmd.Blit(_SsrTex, _source);
            }
            else if (_settings.DebugMode == E_DEBUG.SSR_BLUR_ONLY || _settings.DebugMode == E_DEBUG.SSR_FINAL_WITH_BLUR)
            {

                cmd.Blit(_SsrTex, _DualFilterTexs[0], _material_DualFilter, PASS_DUALFILTER_DOWN);
                for (int i = 0; i < _DualFilterTexs.Length - 1; ++i)
                {
                    cmd.Blit(_DualFilterTexs[i], _DualFilterTexs[i + 1], _material_DualFilter, PASS_DUALFILTER_DOWN);
                }
                for (int i = _DualFilterTexs.Length - 1; i > 0; --i)
                {
                    cmd.Blit(_DualFilterTexs[i], _DualFilterTexs[i - 1], _material_DualFilter, PASS_DUALFILTER_UP);
                }
                cmd.Blit(_DualFilterTexs[0], _SsrTex, _material_DualFilter, PASS_DUALFILTER_UP);

                if (_settings.DebugMode == E_DEBUG.SSR_BLUR_ONLY)
                {
                    cmd.Blit(_SsrTex, _source);
                }
                else
                {
                    cmd.Blit(_TmpCopyTex, _source, _material_SSR, PASS_SSR_COMBINE);
                }
            }
            else if (_settings.DebugMode == E_DEBUG.SSR_FINAL_WITHOUT_BLUR)
            {
                cmd.Blit(_TmpCopyTex, _source, _material_SSR, PASS_SSR_COMBINE);
            }

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }

    [SerializeField]
    SSR_RenderPassSettings _settings = null;
    SSR_RenderPass _pass;
    
    public override void Create()
    {
        _pass = new SSR_RenderPass(_settings);
        _pass.renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(_pass);
    }
}
