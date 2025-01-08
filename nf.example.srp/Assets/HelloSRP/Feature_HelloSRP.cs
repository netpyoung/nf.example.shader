using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.RenderGraphModule.Util;
using UnityEngine.Rendering.Universal;

public sealed class Feature_HelloSRP : ScriptableRendererFeature
{
    sealed class Pass_HelloSRP : ScriptableRenderPass
    {
        private const string PASS_NAME = "HELLO_SRP";

        private readonly Material _material;

        public Pass_HelloSRP(Material material)
        {
            this.requiresIntermediateTexture = false;
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
    } // Pass_HelloSRP

    [SerializeField]
    public Material Material;
    private Pass_HelloSRP _pass;

    public override void Create()
    {
        _pass = new Pass_HelloSRP(Material);
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
} // Feature_HelloSRP
