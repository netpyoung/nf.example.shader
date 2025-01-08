using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;


public class Feature_GammaUIFix : ScriptableRendererFeature
{
    private Pass_DrawUI _drawUIIntoRTPass;
    private Pass_Blit _blitRenderPassesToScreen;
    public Material Material;

    public override void Create()
    {
        _drawUIIntoRTPass = new Pass_DrawUI(RenderPassEvent.AfterRendering);
        _blitRenderPassesToScreen = new Pass_Blit(RenderPassEvent.AfterRendering, Material);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        CameraData cameraData = renderingData.cameraData;
        if (cameraData.cameraType != CameraType.Game)
        {
            return;
        }

        string cameraName = cameraData.camera.name;
        if (cameraName == "UI Camera")
        {
            renderer.EnqueuePass(_drawUIIntoRTPass);
        }
        else if (cameraName == "Main Camera")
        {
            renderer.EnqueuePass(_blitRenderPassesToScreen);
        }
    }

    public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
    {
        CameraData cameraData = renderingData.cameraData;
        if (cameraData.cameraType != CameraType.Game)
        {
            return;
        }

        string cameraName = cameraData.camera.name;
        if (cameraName == "UI Camera")
        {
            _drawUIIntoRTPass.ConfigureInput(ScriptableRenderPassInput.Color);
        }
        else if (cameraName == "Main Camera")
        {
            _blitRenderPassesToScreen.ConfigureInput(ScriptableRenderPassInput.Color);
        }
    }

    class TexRefData : ContextItem
    {
        public TextureHandle texture = TextureHandle.nullHandle;

        public override void Reset()
        {
            texture = TextureHandle.nullHandle;
        }
    }

    class PassData
    {
        public TextureHandle source;
        public TextureHandle destination;
        public Material material;
    }

    class Pass_DrawUI : ScriptableRenderPass
    {
        const string RENDER_TAG = nameof(Pass_DrawUI);

        public Pass_DrawUI(RenderPassEvent renderPassEvent)
        {
            this.renderPassEvent = renderPassEvent;
            requiresIntermediateTexture = true;
        }

        public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
        {
            UniversalCameraData cameraData = frameData.Get<UniversalCameraData>();
            if (cameraData.cameraType != CameraType.Game)
            {
                return;
            }

            UniversalResourceData resourceData = frameData.Get<UniversalResourceData>();
            if (resourceData.isActiveTargetBackBuffer)
            {
                return;
            }

            using (IRasterRenderGraphBuilder builder = renderGraph.AddRasterRenderPass($"Pass_DrawUI", out PassData passData))
            {

                TexRefData texRef;
                if (frameData.Contains<TexRefData>())
                {
                    texRef = frameData.Get<TexRefData>();
                }
                else
                {
                    texRef = frameData.Create<TexRefData>();
                    TextureDesc desc = renderGraph.GetTextureDesc(resourceData.activeColorTexture);
                    desc.name = $"UI Color";
                    desc.clearBuffer = true;
                    texRef.texture = renderGraph.CreateTexture(desc);
                }

                passData.source = resourceData.activeColorTexture;
                passData.destination = texRef.texture;

                builder.UseTexture(input: passData.source);
                builder.SetRenderAttachment(tex: passData.destination, index: 0);
                builder.SetRenderFunc<PassData>(ExecutePass);
            }
        }

        static void ExecutePass(PassData data, RasterGraphContext rgContext)
        {
            Vector4 scaleBias = new Vector4(1, 1, 0, 0);
            Blitter.BlitTexture(rgContext.cmd, data.source, scaleBias, mipLevel: 0, bilinear: false);
        }
    }

    class Pass_Blit : ScriptableRenderPass
    {
        const string RENDER_TAG = nameof(Pass_Blit);

        private Material _material;

        public Pass_Blit(RenderPassEvent renderPassEvent, Material mat)
        {
            this.renderPassEvent = renderPassEvent;
            _material = mat;
        }

        public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
        {
            if (_material == null)
            {
                return;
            }

            UniversalCameraData cameraData = frameData.Get<UniversalCameraData>();
            if (cameraData.cameraType != CameraType.Game)
            {
                return;
            }

            using (IRasterRenderGraphBuilder builder = renderGraph.AddRasterRenderPass($"Pass_Blit", out PassData passData))
            {
                UniversalResourceData resourceData = frameData.Get<UniversalResourceData>();

                TexRefData texRef;
                if (frameData.Contains<TexRefData>())
                {
                    texRef = frameData.Get<TexRefData>();
                }
                else
                {
                    return;
                }

                passData.source = texRef.texture;
                passData.destination = resourceData.activeColorTexture;
                passData.material = _material;

                builder.UseTexture(input: passData.source);
                builder.SetRenderAttachment(tex: passData.destination, index: 0);
                builder.SetRenderFunc<PassData>(ExecutePass);
            }
        }

        static void ExecutePass(PassData data, RasterGraphContext rgContext)
        {
            Vector4 scaleBias = new Vector4(1, 1, 0, 0);
            Blitter.BlitTexture(rgContext.cmd, data.source, scaleBias, data.material, pass: 0);
        }

    }
}