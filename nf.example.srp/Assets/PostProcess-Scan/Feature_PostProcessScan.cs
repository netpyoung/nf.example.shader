using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.RenderGraphModule.Util;
using UnityEngine.Rendering.Universal;

public class Feature_PostProcessScan : ScriptableRendererFeature
{
    class Pass_Blit : ScriptableRenderPass
    {
        const string RENDER_TAG = nameof(Pass_Blit);
        const string PASS_NAME = "POSTPROCESS_SCAN";
        private readonly Material _material;

        public Pass_Blit(Material material)
        {
            _material = material;
        }

        public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
        {
            UniversalResourceData resourceData = frameData.Get<UniversalResourceData>();
            if (resourceData.isActiveTargetBackBuffer)
            {
                return;
            }

            TextureHandle srcCamColor = resourceData.activeColorTexture;
            if (!srcCamColor.IsValid())
            {
                return;
            }

            TextureHandle srcHandle = resourceData.activeColorTexture;
            TextureHandle dstHandle;
            {
                TextureDesc destinationDesc = renderGraph.GetTextureDesc(srcHandle);
                destinationDesc.name = $"CameraColor-{PASS_NAME}";
                destinationDesc.clearBuffer = false;
                dstHandle = renderGraph.CreateTexture(destinationDesc);
            }


            RenderGraphUtils.BlitMaterialParameters blitParam = new RenderGraphUtils.BlitMaterialParameters(srcHandle, dstHandle, _material, shaderPass: 0);
            renderGraph.AddBlitPass(blitParam, passName: PASS_NAME);


            resourceData.cameraColor = dstHandle;
        }
    }

    private Pass_Blit _pass;
    public Material Material;

    public override void Create()
    {
        _pass = new Pass_Blit(Material);
        _pass.renderPassEvent = RenderPassEvent.AfterRenderingPostProcessing;
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
}


