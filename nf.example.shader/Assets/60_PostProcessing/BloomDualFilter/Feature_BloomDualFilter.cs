using System;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class Feature_BloomDualFilter : ScriptableRendererFeature
{
    class Pass_BloomDualFilter : ScriptableRenderPass
    {
        const string RENDER_TAG = nameof(Pass_BloomDualFilter);
        const int BLOOM_THRESHOLD_PASS = 0;
        const int BLOOM_COMBINE_PASS = 1;
        const int DUALFILTER_DOWN_PASS = 0;
        const int DUALFILTER_UP_PASS = 1;

        public int downsample = 8;

        Material _materialBloom;
        Material _materialDualFilter;
        
        RenderTargetIdentifier _currentTarget;
        RenderTargetIdentifier _destTarget;
        RenderTargetHandle _destination;

        int _bloomBrightRT_Id;
        int _dualFilterDownRT_Id;
        int _dualFilterUpRT_Id;
        int _dualFilterDownRT_Id1;
        int _dualFilterUpRT_Id1;
        int _dualFilterDownRT_Id2;
        int _dualFilterUpRT_Id2;
        int _dualFilterDownRT_Id3;
        int _dualFilterUpRT_Id3;

        RenderTargetIdentifier _bloomBrightRT;
        RenderTargetIdentifier _dualFilterDownRT;
        RenderTargetIdentifier _dualFilterUpRT;
        RenderTargetIdentifier _dualFilterDownRT1;
        RenderTargetIdentifier _dualFilterUpRT1;
        RenderTargetIdentifier _dualFilterDownRT2;
        RenderTargetIdentifier _dualFilterUpRT2;
        RenderTargetIdentifier _dualFilterDownRT3;
        RenderTargetIdentifier _dualFilterUpRT3;

        public Pass_BloomDualFilter(Material materialBloom, Material materialDualFilter)
        {
            _materialBloom = materialBloom;
            _materialDualFilter = materialDualFilter;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
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
            if (renderingData.cameraData.isSceneViewCamera)
            {
                return;
            }

            cmd.Blit(_currentTarget, _bloomBrightRT, _materialBloom, BLOOM_THRESHOLD_PASS);

            //cmd.Blit(_bloomBrightRT, _dualFilterDownRT, _materialDualFilter, DUALFILTER_DOWN_PASS);
            cmd.Blit(_bloomBrightRT, _dualFilterDownRT, _materialDualFilter);
            cmd.Blit(_dualFilterDownRT, _dualFilterDownRT1, _materialDualFilter, DUALFILTER_DOWN_PASS);
            cmd.Blit(_dualFilterDownRT1, _dualFilterDownRT2, _materialDualFilter, DUALFILTER_DOWN_PASS);
            cmd.Blit(_dualFilterDownRT2, _dualFilterDownRT3, _materialDualFilter, DUALFILTER_DOWN_PASS);

            //cmd.Blit(_dualFilterDownRT2, _dualFilterUpRT2, _materialDualFilter, DUALFILTER_UP_PASS);

            cmd.Blit(_dualFilterDownRT3, _dualFilterUpRT3, _materialDualFilter, DUALFILTER_UP_PASS);
            cmd.Blit(_dualFilterUpRT3, _dualFilterUpRT2, _materialDualFilter, DUALFILTER_UP_PASS);
            cmd.Blit(_dualFilterUpRT2, _dualFilterUpRT1, _materialDualFilter, DUALFILTER_UP_PASS);
            cmd.Blit(_dualFilterUpRT1, _dualFilterUpRT, _materialDualFilter);
            //cmd.Blit(_dualFilterUpRT1, _dualFilterUpRT, _materialDualFilter, DUALFILTER_UP_PASS);

            //cmd.Blit(_bloomBrightRT, _dualFilterDownRT, _materialDualFilter, DUALFILTER_DOWN_PASS);
            //cmd.Blit(_dualFilterDownRT, _dualFilterUpRT, _materialDualFilter, DUALFILTER_UP_PASS);

            cmd.SetGlobalTexture(_bloomBrightRT_Id, _bloomBrightRT);
            cmd.SetGlobalTexture(_dualFilterUpRT_Id, _dualFilterUpRT);

            cmd.Blit(_currentTarget, _destTarget, _materialBloom, BLOOM_COMBINE_PASS);
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            var width = cameraTextureDescriptor.width;
            var height = cameraTextureDescriptor.height;

            _bloomBrightRT_Id = Shader.PropertyToID("_BloomNonBlurTex");

            _dualFilterDownRT_Id = Shader.PropertyToID("_dualFilterDownRT");
            _dualFilterDownRT_Id1 = Shader.PropertyToID("_dualFilterDownRT1");
            _dualFilterDownRT_Id2 = Shader.PropertyToID("_dualFilterDownRT2");
            _dualFilterDownRT_Id3 = Shader.PropertyToID("_dualFilterDownRT3");
            _dualFilterUpRT_Id3 = Shader.PropertyToID("_BloomBlurTex3");
            _dualFilterUpRT_Id2 = Shader.PropertyToID("_BloomBlurTex2");
            _dualFilterUpRT_Id1 = Shader.PropertyToID("_BloomBlurTex1");
            _dualFilterUpRT_Id = Shader.PropertyToID("_BloomBlurTex");


            RenderTextureFormat tf = RenderTextureFormat.ARGB32;
            
            cmd.GetTemporaryRT(_bloomBrightRT_Id, width / 4, height / 4, 0, FilterMode.Bilinear, tf);

            cmd.GetTemporaryRT(_dualFilterDownRT_Id, width / 8, height / 8, 0, FilterMode.Bilinear, tf);
            cmd.GetTemporaryRT(_dualFilterDownRT_Id1, width / 16, height / 16, 0, FilterMode.Bilinear, tf);
            cmd.GetTemporaryRT(_dualFilterDownRT_Id2, width / 32, height / 32, 0, FilterMode.Bilinear, tf);
            cmd.GetTemporaryRT(_dualFilterDownRT_Id3, width / 64, height / 64, 0, FilterMode.Bilinear, tf);

            cmd.GetTemporaryRT(_dualFilterUpRT_Id3, width / 32, height / 32, 0, FilterMode.Bilinear, tf);
            cmd.GetTemporaryRT(_dualFilterUpRT_Id2, width / 16, height / 16, 0, FilterMode.Bilinear, tf);
            cmd.GetTemporaryRT(_dualFilterUpRT_Id1, width / 8, height / 8, 0, FilterMode.Bilinear, tf);
            cmd.GetTemporaryRT(_dualFilterUpRT_Id, width / 4, height / 4, 0, FilterMode.Bilinear, tf);



            //cmd.GetTemporaryRT(_bloomBrightRT_Id, width / 8, height / 8, 0, FilterMode.Point, RenderTextureFormat.ARGB32);
            //cmd.GetTemporaryRT(_dualFilterDownRT_Id, width / 16, height / 16, 0, FilterMode.Point, RenderTextureFormat.ARGB32);
            //cmd.GetTemporaryRT(_dualFilterUpRT_Id, width / 8, height / 8, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);


            _bloomBrightRT = new RenderTargetIdentifier(_bloomBrightRT_Id);
            _dualFilterDownRT = new RenderTargetIdentifier(_dualFilterDownRT_Id);
            _dualFilterDownRT1 = new RenderTargetIdentifier(_dualFilterDownRT_Id1);
            _dualFilterDownRT2 = new RenderTargetIdentifier(_dualFilterDownRT_Id2);
            _dualFilterDownRT3 = new RenderTargetIdentifier(_dualFilterDownRT_Id3);
            _dualFilterUpRT3 = new RenderTargetIdentifier(_dualFilterUpRT_Id3);
            _dualFilterUpRT2 = new RenderTargetIdentifier(_dualFilterUpRT_Id2);
            _dualFilterUpRT1 = new RenderTargetIdentifier(_dualFilterUpRT_Id1);
            _dualFilterUpRT = new RenderTargetIdentifier(_dualFilterUpRT_Id);


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

        internal void Setup(RenderTargetIdentifier cameraColorTarget, RenderTargetHandle cameraHandle)
        {
            this._currentTarget = cameraColorTarget;
            this._destination = cameraHandle;
            this._destTarget = _destination.Identifier();
        }

        public override void FrameCleanup(CommandBuffer cmd)
        {
            if (cmd == null)
            {
                throw new ArgumentNullException("cmd");
            }

            //cmd.ReleaseTemporaryRT(DrawUIIntoRTPass.UITemporaryRT);

            base.FrameCleanup(cmd);
        }
    }

    Pass_BloomDualFilter _pass;
    public Material MaterialBloom;
    public Material MaterialDualFilter;

    public override void Create()
    {
        _pass = new Pass_BloomDualFilter(MaterialBloom, MaterialDualFilter);
        _pass.renderPassEvent = RenderPassEvent.AfterRenderingPostProcessing;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        RenderTargetHandle cameraHandle = RenderTargetHandle.CameraTarget;
        _pass.Setup(renderer.cameraColorTarget, cameraHandle);
        renderer.EnqueuePass(_pass);
    }
}
