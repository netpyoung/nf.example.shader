using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class BloomDualFilter_RenderPassFeature : ScriptableRendererFeature
{
    class BloomDualFilter_RenderPass : ScriptableRenderPass
    {
        const string RENDER_TAG = nameof(BloomDualFilter_RenderPass);
        
        const int PASS_BLOOM_THRESHOLD = 0;
        const int PASS_BLOOM_COMBINE = 1;

        const int PASS_DUALFILTER_DOWN = 0;
        const int PASS_DUALFILTER_UP = 1;

        public int downsample = 8;

        Material _materialBloom;
        Material _materialDualFilter;

        RenderTargetIdentifier _source;
        RenderTargetIdentifier _destination;

        readonly static int _BloomBrightTex = Shader.PropertyToID("_BloomNonBlurTex");
        readonly static int _DualFilterDownTex = Shader.PropertyToID("_DualFilterDownTex");
        readonly static int _DualFilterDownTex1 = Shader.PropertyToID("_DualFilterDownTex1");
        readonly static int _DualFilterDownTex2 = Shader.PropertyToID("_DualFilterDownTex2");
        readonly static int _DualFilterDownTex3 = Shader.PropertyToID("_DualFilterDownTex3");
        readonly static int _DualFilterUpTex3 = Shader.PropertyToID("_BloomBlurTex3");
        readonly static int _DualFilterUpTex2 = Shader.PropertyToID("_BloomBlurTex2");
        readonly static int _DualFilterUpTex1 = Shader.PropertyToID("_BloomBlurTex1");
        readonly static int _DualFilterUpTex = Shader.PropertyToID("_BloomBlurTex");


        RenderTargetIdentifier _bloomBrightRT;
        RenderTargetIdentifier _dualFilterDownRT;
        RenderTargetIdentifier _dualFilterUpRT;
        RenderTargetIdentifier _dualFilterDownRT1;
        RenderTargetIdentifier _dualFilterUpRT1;
        RenderTargetIdentifier _dualFilterDownRT2;
        RenderTargetIdentifier _dualFilterUpRT2;
        RenderTargetIdentifier _dualFilterDownRT3;
        RenderTargetIdentifier _dualFilterUpRT3;

        public BloomDualFilter_RenderPass(Material materialBloom, Material materialDualFilter)
        {
            _materialBloom = materialBloom;
            _materialDualFilter = materialDualFilter;
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            this._source = renderingData.cameraData.renderer.cameraColorTarget;
            this._destination = RenderTargetHandle.CameraTarget.Identifier();
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.isSceneViewCamera)
            {
                return;
            }

            CommandBuffer cmd = CommandBufferPool.Get(RENDER_TAG);


            cmd.Blit(_source, _bloomBrightRT, _materialBloom, PASS_BLOOM_THRESHOLD);

            //cmd.Blit(_bloomBrightRT, _dualFilterDownRT, _materialDualFilter, DUALFILTER_DOWN_PASS);
            cmd.Blit(_bloomBrightRT, _dualFilterDownRT, _materialDualFilter);
            cmd.Blit(_dualFilterDownRT, _dualFilterDownRT1, _materialDualFilter, PASS_DUALFILTER_DOWN);
            cmd.Blit(_dualFilterDownRT1, _dualFilterDownRT2, _materialDualFilter, PASS_DUALFILTER_DOWN);
            cmd.Blit(_dualFilterDownRT2, _dualFilterDownRT3, _materialDualFilter, PASS_DUALFILTER_DOWN);

            //cmd.Blit(_dualFilterDownRT2, _dualFilterUpRT2, _materialDualFilter, DUALFILTER_UP_PASS);

            cmd.Blit(_dualFilterDownRT3, _dualFilterUpRT3, _materialDualFilter, PASS_DUALFILTER_UP);
            cmd.Blit(_dualFilterUpRT3, _dualFilterUpRT2, _materialDualFilter, PASS_DUALFILTER_UP);
            cmd.Blit(_dualFilterUpRT2, _dualFilterUpRT1, _materialDualFilter, PASS_DUALFILTER_UP);
            cmd.Blit(_dualFilterUpRT1, _dualFilterUpRT, _materialDualFilter);
            //cmd.Blit(_dualFilterUpRT1, _dualFilterUpRT, _materialDualFilter, DUALFILTER_UP_PASS);

            //cmd.Blit(_bloomBrightRT, _dualFilterDownRT, _materialDualFilter, DUALFILTER_DOWN_PASS);
            //cmd.Blit(_dualFilterDownRT, _dualFilterUpRT, _materialDualFilter, DUALFILTER_UP_PASS);

            cmd.SetGlobalTexture(_BloomBrightTex, _bloomBrightRT);
            cmd.SetGlobalTexture(_DualFilterUpTex, _dualFilterUpRT);

            cmd.Blit(_source, _destination, _materialBloom, PASS_BLOOM_COMBINE);

            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            var width = cameraTextureDescriptor.width;
            var height = cameraTextureDescriptor.height;


            RenderTextureFormat tf = RenderTextureFormat.ARGB32;

            cmd.GetTemporaryRT(_BloomBrightTex, width / 4, height / 4, 0, FilterMode.Bilinear, tf);

            cmd.GetTemporaryRT(_DualFilterDownTex, width / 8, height / 8, 0, FilterMode.Bilinear, tf);
            cmd.GetTemporaryRT(_DualFilterDownTex1, width / 16, height / 16, 0, FilterMode.Bilinear, tf);
            cmd.GetTemporaryRT(_DualFilterDownTex2, width / 32, height / 32, 0, FilterMode.Bilinear, tf);
            cmd.GetTemporaryRT(_DualFilterDownTex3, width / 64, height / 64, 0, FilterMode.Bilinear, tf);

            cmd.GetTemporaryRT(_DualFilterUpTex3, width / 32, height / 32, 0, FilterMode.Bilinear, tf);
            cmd.GetTemporaryRT(_DualFilterUpTex2, width / 16, height / 16, 0, FilterMode.Bilinear, tf);
            cmd.GetTemporaryRT(_DualFilterUpTex1, width / 8, height / 8, 0, FilterMode.Bilinear, tf);
            cmd.GetTemporaryRT(_DualFilterUpTex, width / 4, height / 4, 0, FilterMode.Bilinear, tf);

            _bloomBrightRT = new RenderTargetIdentifier(_BloomBrightTex);
            _dualFilterDownRT = new RenderTargetIdentifier(_DualFilterDownTex);
            _dualFilterDownRT1 = new RenderTargetIdentifier(_DualFilterDownTex1);
            _dualFilterDownRT2 = new RenderTargetIdentifier(_DualFilterDownTex2);
            _dualFilterDownRT3 = new RenderTargetIdentifier(_DualFilterDownTex3);
            _dualFilterUpRT3 = new RenderTargetIdentifier(_DualFilterUpTex3);
            _dualFilterUpRT2 = new RenderTargetIdentifier(_DualFilterUpTex2);
            _dualFilterUpRT1 = new RenderTargetIdentifier(_DualFilterUpTex1);
            _dualFilterUpRT = new RenderTargetIdentifier(_DualFilterUpTex);


            ConfigureTarget(_bloomBrightRT);
            ConfigureTarget(_dualFilterDownRT);
            ConfigureTarget(_dualFilterUpRT);
            ConfigureTarget(_dualFilterDownRT1);
            ConfigureTarget(_dualFilterUpRT1);
            ConfigureTarget(_dualFilterDownRT2);
            ConfigureTarget(_dualFilterUpRT2);
            ConfigureTarget(_dualFilterDownRT3);
            ConfigureTarget(_dualFilterUpRT3);
        }
    }

    BloomDualFilter_RenderPass _pass;
    public Material MaterialBloom;
    public Material MaterialDualFilter;

    public override void Create()
    {
        _pass = new BloomDualFilter_RenderPass(MaterialBloom, MaterialDualFilter);
        _pass.renderPassEvent = RenderPassEvent.AfterRenderingPostProcessing;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(_pass);
    }
}
