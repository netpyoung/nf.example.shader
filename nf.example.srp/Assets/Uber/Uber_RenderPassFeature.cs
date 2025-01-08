using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.RenderGraphModule.Util;
using UnityEngine.Rendering.Universal;

public class Uber_RenderPassFeature : ScriptableRendererFeature
{
    [SerializeField]
    Uber_RenderPassSettings _settings = null;
    Uber_RenderPass _pass;

    public override void Create()
    {
        _pass = new Uber_RenderPass(_settings);
        _pass.renderPassEvent = RenderPassEvent.AfterRendering;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType == CameraType.Game)
        {
            renderer.EnqueuePass(_pass);
        }
    }

    public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType == CameraType.Game)
        {
            _pass.ConfigureInput(ScriptableRenderPassInput.Color);
        }
    }


    // ========================================================================================================================================
    [Serializable]
    public class Uber_RenderPassSettings
    {
        public bool _UBER_A;
        public bool _UBER_B;
    }


    // ========================================================================================================================================
    class Uber_RenderPass : ScriptableRenderPass
    {
        Material _mat_uber;

        public Uber_RenderPass(Uber_RenderPassSettings settings)
        {
            if (_mat_uber == null)
            {
                _mat_uber = CoreUtils.CreateEngineMaterial("Hidden/Uber");
            }

            if (settings._UBER_A)
            {
                _mat_uber.EnableKeyword("_UBER_A");
            }
            else
            {
                _mat_uber.DisableKeyword("_UBER_A");
            }

            if (settings._UBER_B)
            {
                _mat_uber.EnableKeyword("_UBER_B");
            }
            else
            {
                _mat_uber.DisableKeyword("_UBER_B");
            }
        }

        public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
        {
            UniversalResourceData resourceData = frameData.Get<UniversalResourceData>();

            TextureHandle source = resourceData.activeColorTexture;
            TextureDesc destinationDesc = renderGraph.GetTextureDesc(source);

            destinationDesc.name = $"CameraColor-{passName}";
            destinationDesc.clearBuffer = false;

            TextureHandle destination = renderGraph.CreateTexture(destinationDesc);
            RenderGraphUtils.BlitMaterialParameters para = new RenderGraphUtils.BlitMaterialParameters(source, destination, _mat_uber, shaderPass: 0);
            renderGraph.AddBlitPass(para, passName: passName);
            resourceData.cameraColor = destination;
        }
    }
}
