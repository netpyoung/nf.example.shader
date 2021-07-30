using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class Feature_BloomDualFilter : ScriptableRendererFeature
{
    class Pass_BloomDualFilter : ScriptableRenderPass
    {
        const string RENDER_TAG = "Pass_Kawase";
        public int downsample = 8;

        Material _materialBloom;
        Material _materialDualFilter;
        
        RenderTargetIdentifier _currentTarget;
        RenderTargetIdentifier _destTarget;
        RenderTargetHandle _destination;
        int _dualFilterDownRT_Id;
        int _dualFilterUpRT_Id;
        int _bloomBrightRT_Id;

        RenderTargetIdentifier _dualFilterDownRT;
        RenderTargetIdentifier _dualFilterUpRT;
        RenderTargetIdentifier _bloomBrightRT;

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

            cmd.Blit(_currentTarget, _bloomBrightRT, _materialBloom, 0);

            cmd.Blit(_bloomBrightRT, _dualFilterDownRT, _materialDualFilter, 0);
            cmd.Blit(_dualFilterDownRT, _dualFilterUpRT, _materialDualFilter, 1);

            cmd.SetGlobalTexture(_bloomBrightRT_Id, _bloomBrightRT);
            cmd.SetGlobalTexture(_dualFilterUpRT_Id, _dualFilterUpRT);

            cmd.Blit(_currentTarget, _destTarget, _materialBloom, 1);
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            var width = cameraTextureDescriptor.width;
            var height = cameraTextureDescriptor.height;

            _dualFilterDownRT_Id = Shader.PropertyToID("_dualFilterDownRT");
            _dualFilterUpRT_Id = Shader.PropertyToID("_BloomBlurTex");
            _bloomBrightRT_Id = Shader.PropertyToID("_BloomNonBlurTex");

            //cmd.GetTemporaryRT(_dualFilterDownRT_Id, width / 4 , height / 4, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);
            //cmd.GetTemporaryRT(_dualFilterUpRT_Id, width / 2, height / 2, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);
            //cmd.GetTemporaryRT(_bloomBrightRT_Id, width / 2, height / 2, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);

            cmd.GetTemporaryRT(_dualFilterDownRT_Id, width / 8, height / 8, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);
            cmd.GetTemporaryRT(_dualFilterUpRT_Id, width / 4, height / 4, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);
            cmd.GetTemporaryRT(_bloomBrightRT_Id, width / 4, height / 4, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);


            _dualFilterDownRT = new RenderTargetIdentifier(_dualFilterDownRT_Id);
            _dualFilterUpRT = new RenderTargetIdentifier(_dualFilterUpRT_Id);
            _bloomBrightRT = new RenderTargetIdentifier(_bloomBrightRT_Id);

            ConfigureTarget(_dualFilterDownRT);
            ConfigureTarget(_dualFilterUpRT);
            ConfigureTarget(_bloomBrightRT);
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
