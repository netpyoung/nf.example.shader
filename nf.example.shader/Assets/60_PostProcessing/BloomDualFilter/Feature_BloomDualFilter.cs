using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
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

        private Material _materialBloom;
        private Material _materialDualFilter;
        private int _BloomNonBlurTex_Id;
        private int _BloomBlurTex_Id;
        private int _dualFilterStep;

        public Pass_BloomDualFilter(int dualFilterStep, Material materialBloom, Material materialDualFilter)
        {
            _dualFilterStep = dualFilterStep;
            _materialBloom = materialBloom;
            _materialDualFilter = materialDualFilter;
            _BloomNonBlurTex_Id = Shader.PropertyToID("_BloomNonBlurTex");
            _BloomBlurTex_Id = Shader.PropertyToID("_BloomBlurTex");
        }

        int _MeasureStep(int width, int height)
        {
            int min = Math.Min(width, height);
            int step = 0;
            while (min > 1)
            {
                min >>= 1;
                step++;
            }
            step++;
            return step;
        }

        public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
        {
            string passName = "Unsafe Pass";

            UniversalCameraData cameraData = frameData.Get<UniversalCameraData>();
            if (cameraData.camera.cameraType != CameraType.Game)
            {
                return;
            }

            if (_materialBloom == null)
            {
                return;
            }

            if (_materialDualFilter == null)
            {
                return;
            }

            if (!cameraData.postProcessEnabled)
            {
                return;
            }

            using (IUnsafeRenderGraphBuilder builder = renderGraph.AddUnsafePass(passName, out PassData passData))
            {
                UniversalResourceData resourceData = frameData.Get<UniversalResourceData>();
                TextureDesc mainDesc;
                {
                    mainDesc = resourceData.activeColorTexture.GetDescriptor(renderGraph);
                    mainDesc.msaaSamples = MSAASamples.None;
                    mainDesc.clearBuffer = false;
                }

                TextureHandle destination;
                {
                    mainDesc.name = "destination";
                    destination = renderGraph.CreateTexture(mainDesc);
                }

                TextureHandle bloomBrightHandle;
                {
                    mainDesc.name = "bloomBrightHandle";
                    bloomBrightHandle = renderGraph.CreateTexture(mainDesc);
                }

                int fromDiv = 2;
                int measureStep = _MeasureStep(mainDesc.width / fromDiv, mainDesc.height / fromDiv);
                int dualFilterStep = Math.Min(measureStep, _dualFilterStep);
                TextureHandle[] dualFilterHandles = new TextureHandle[dualFilterStep];

                for (int i = 0; i < dualFilterStep; ++i)
                {
                    int div = 1 << i; // 1, 2, 4, 8 ...
                    div = div * fromDiv; // 8, 16, 32, 64 ...
                    int w = mainDesc.width / div;
                    int h = mainDesc.height / div;
                    TextureDesc newDesc = mainDesc;
                    newDesc.name = $"dualFilterHandles_{i}";
                    newDesc.width = w;
                    newDesc.height = h;
                    dualFilterHandles[i] = renderGraph.CreateTexture(newDesc);
                }

                passData.srcColor = resourceData.activeColorTexture;
                passData.BloomBrightHandle = bloomBrightHandle;
                passData.DualFilterHandles = dualFilterHandles;
                passData.Destination = destination;
                passData.DualFilterStep = _dualFilterStep;
                passData.BloomBlurTex_Id = _BloomBlurTex_Id;
                passData.BloomNonBlurTex_Id = _BloomNonBlurTex_Id;
                passData.MaterialBloom = _materialBloom;
                passData.MaterialDualFilter = _materialDualFilter;

                builder.UseTexture(passData.srcColor);
                builder.UseTexture(passData.Destination, AccessFlags.WriteAll);
                builder.UseTexture(passData.BloomBrightHandle, AccessFlags.WriteAll);
                for (int i = 0; i < passData.DualFilterHandles.Length; ++i)
                {
                    builder.UseTexture(passData.DualFilterHandles[i], AccessFlags.WriteAll);
                }
                builder.AllowPassCulling(value: false);
                builder.SetRenderFunc<PassData>(ExecutePass);
            }
        }

        public class PassData
        {
            public TextureHandle srcColor;
            public TextureHandle Destination;
            public TextureHandle BloomBrightHandle;
            public TextureHandle[] DualFilterHandles;
            public Material MaterialBloom;
            public Material MaterialDualFilter;
            public int DualFilterStep;
            public int BloomNonBlurTex_Id;
            public int BloomBlurTex_Id;
        }

        static void ExecutePass(PassData data, UnsafeGraphContext context)
        {
            CommandBuffer unsafeCmd = CommandBufferHelpers.GetNativeCommandBuffer(context.cmd);

            Vector4 scaleBias = new Vector4(1, 1, 0, 0);

            context.cmd.SetRenderTarget(data.Destination);
            Blitter.BlitTexture(unsafeCmd, data.srcColor, scaleBias, mipLevel: 0, bilinear: false);

            context.cmd.SetRenderTarget(data.BloomBrightHandle);
            Blitter.BlitTexture(unsafeCmd, data.Destination, scaleBias, material: data.MaterialBloom, pass: BLOOM_THRESHOLD_PASS);

            context.cmd.SetRenderTarget(data.DualFilterHandles[0]);
            Blitter.BlitTexture(unsafeCmd, data.BloomBrightHandle, scaleBias, material: data.MaterialBloom, pass: BLOOM_THRESHOLD_PASS);


            for (int i = 0; i < data.DualFilterStep / 2 - 1; ++i)
            {
                context.cmd.SetRenderTarget(data.DualFilterHandles[i + 1]);
                Blitter.BlitTexture(unsafeCmd, data.DualFilterHandles[i], scaleBias, material: data.MaterialDualFilter, pass: DUALFILTER_DOWN_PASS);
            }

            for (int i = data.DualFilterStep / 2 - 1; i > 0; --i)
            {
                context.cmd.SetRenderTarget(data.DualFilterHandles[i - 1]);
                Blitter.BlitTexture(unsafeCmd, data.DualFilterHandles[i], scaleBias, material: data.MaterialDualFilter, pass: DUALFILTER_UP_PASS);
            }

            context.cmd.SetGlobalTexture(data.BloomNonBlurTex_Id, data.BloomBrightHandle);
            context.cmd.SetGlobalTexture(data.BloomBlurTex_Id, data.DualFilterHandles[0]);
            context.cmd.SetRenderTarget(data.srcColor);
            Blitter.BlitTexture(unsafeCmd, data.Destination, scaleBias, material: data.MaterialBloom, pass: BLOOM_COMBINE_PASS);
        }
    }

    private Pass_BloomDualFilter _pass;
    public Material MaterialBloom;
    public Material MaterialDualFilter;
    public int DualFilterStep;

    public override void Create()
    {
        DualFilterStep = Math.Max(DualFilterStep, 0);

        _pass = new Pass_BloomDualFilter(DualFilterStep, MaterialBloom, MaterialDualFilter);
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
