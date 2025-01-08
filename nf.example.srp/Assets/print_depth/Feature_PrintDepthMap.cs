using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.RenderGraphModule.Util;
using UnityEngine.Rendering.Universal;

public class Feature_PrintDepthMap : ScriptableRendererFeature
{
    class Pass_PrintDepthMap : ScriptableRenderPass
    {
        const string RENDER_TAG = nameof(Pass_PrintDepthMap);
        const string PASS_NAME = "PRINT_DEPTH";

        private readonly Material _material;
        private Volume_PrintDepthMap _depthMap;

        public Pass_PrintDepthMap(Material material)
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

            UniversalCameraData cameraData = frameData.Get<UniversalCameraData>();
            if (cameraData.cameraType != CameraType.Game)
            {
                return;
            }

            if (_material == null)
            {
                return;
            }

            if (!cameraData.postProcessEnabled)
            {
                return;
            }

            if (_depthMap == null)
            {
                VolumeStack stack = VolumeManager.instance.stack;
                _depthMap = stack.GetComponent<Volume_PrintDepthMap>();
                if (_depthMap == null)
                {
                    return;
                }
            }

            if (!_depthMap.IsActive())
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

    public Material Material;
    private Pass_PrintDepthMap _pass;

    public override void Create()
    {
        _pass = new Pass_PrintDepthMap(Material);
        _pass.renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
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
