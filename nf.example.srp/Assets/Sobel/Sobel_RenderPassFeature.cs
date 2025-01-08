using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.RenderGraphModule.Util;
using UnityEngine.Rendering.Universal;

public class Sobel_RenderPassFeature : ScriptableRendererFeature
{
    [SerializeField]
    private Sobel_RenderPassSettings _settings = null;
    private Sobel_RenderPass _pass;

    public override void Create()
    {
        _pass = new Sobel_RenderPass(_settings);
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
    public class Sobel_RenderPassSettings
    {
        [Range(0.0005f, 0.0025f)] public float _LineThickness;
    }


    // ========================================================================================================================================
    private class Sobel_RenderPass : ScriptableRenderPass
    {
        private const int PASS_SobelFilter = 0;

        private Material _sobel_material;

        public Sobel_RenderPass(Sobel_RenderPassSettings settings)
        {
            if (_sobel_material == null)
            {
                _sobel_material = CoreUtils.CreateEngineMaterial("srp/Sobel");
            }
            _sobel_material.SetFloat("_LineThickness", settings._LineThickness);
        }

        public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
        {
            UniversalResourceData resourceData = frameData.Get<UniversalResourceData>();

            TextureHandle source = resourceData.activeColorTexture;
            TextureDesc destinationDesc = renderGraph.GetTextureDesc(source);

            destinationDesc.name = $"CameraColor-{passName}";
            destinationDesc.clearBuffer = false;

            TextureHandle destination = renderGraph.CreateTexture(destinationDesc);
            RenderGraphUtils.BlitMaterialParameters para = new RenderGraphUtils.BlitMaterialParameters(source, destination, _sobel_material, shaderPass: PASS_SobelFilter);
            renderGraph.AddBlitPass(para, passName: passName);
            resourceData.cameraColor = destination;
        }
    }
}