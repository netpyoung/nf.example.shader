using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class Sobel_RenderPassFeature : ScriptableRendererFeature
{

    [Serializable]
    public class Sobel_RenderPassSettings
    {
        [Range(0.0005f, 0.0025f)] public float _LineThickness;
    }

    class Sobel_RenderPass : ScriptableRenderPass
    {
        Sobel_RenderPassSettings _settings;
        readonly static int _SobelTex = Shader.PropertyToID("_SobelTex ");
        const int PASS_SobelFilter = 0;

        RenderTargetIdentifier _colorBuffer;
        Material _sobel_material;
        public Sobel_RenderPass(Sobel_RenderPassSettings settings)
        {
            _settings = settings;
            if (_sobel_material == null)
            {
                _sobel_material = CoreUtils.CreateEngineMaterial("Hidden/Sobel");
            }
            _sobel_material.SetFloat("_LineThickness", settings._LineThickness);
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            _colorBuffer = renderingData.cameraData.renderer.cameraColorTarget;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get(nameof(Sobel_RenderPass));
            int w = renderingData.cameraData.camera.pixelWidth;
            int h = renderingData.cameraData.camera.pixelHeight;
            cmd.GetTemporaryRT(_SobelTex, w, h, 0, FilterMode.Bilinear);
            Blit(cmd, _colorBuffer, _SobelTex, _sobel_material, PASS_SobelFilter);
            Blit(cmd, _SobelTex, _colorBuffer);
            cmd.ReleaseTemporaryRT(_SobelTex);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
        }
    }

    [SerializeField]
    Sobel_RenderPassSettings _settings;
    Sobel_RenderPass _pass;

    public override void Create()
    {
        _pass = new Sobel_RenderPass(_settings);
        _pass.renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(_pass);
    }
}


