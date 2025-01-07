using System;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;

public class CrossFilter_RenderPassFeature : ScriptableRendererFeature
{
    [SerializeField]
    private CrossFilter_RenderPassSettings settings;
    private CrossFilter_RenderPass _pass;

    public override void Create()
    {
        _pass = new CrossFilter_RenderPass(settings);
        _pass.renderPassEvent = RenderPassEvent.AfterRendering;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType != CameraType.Game)
        {
            return;
        }
        _pass.Setup(renderingData.cameraData.cameraTargetDescriptor);
        renderer.EnqueuePass(_pass);
    }

    protected override void Dispose(bool disposing)
    {
        _pass.Dispose();
    }

    // ========================================================================================================================================
    [Serializable]
    public struct CrossFilter_RenderPassSettings
    {
    }


    // ========================================================================================================================================
    private sealed class RTCollection : IDisposable
    {
        public const int PASS_BLOOM_THRESHOLD = 0;
        public const int PASS_BLOOM_COMPOSITE = 1;
        public const int PASS_CROSSFILTER_GAUSSIAN_VERT = 0;
        public const int PASS_CROSSFILTER_GAUSSIAN_HORIZ = 1;
        public const int PASS_CROSSFILTER_STAR_RAY = 2;
        public const int PASS_CROSSFILTER_MERGE_STAR = 3;

        public readonly int _BlitTexture = Shader.PropertyToID("_BlitTexture");
        public readonly int _ScaledTex = Shader.PropertyToID("_ScaledTex");
        public readonly int _BrightTex = Shader.PropertyToID("_BrightTex");
        public readonly int _BaseStarBlurredTex1 = Shader.PropertyToID("_BaseStarBlurredTex1");
        public readonly int _BaseStarBlurredTex2 = Shader.PropertyToID("_BaseStarBlurredTex2");
        public static readonly int[] _StarTexs = new int[8] {
            Shader.PropertyToID("_StarTex0"),
            Shader.PropertyToID("_StarTex1"),
            Shader.PropertyToID("_StarTex2"),
            Shader.PropertyToID("_StarTex3"),
            Shader.PropertyToID("_StarTex4"),
            Shader.PropertyToID("_StarTex5"),
            Shader.PropertyToID("_StarTex6"),
            Shader.PropertyToID("_StarTex7"),
        };

        private RTHandle _scaledRT;
        private RTHandle _brightRT;
        private RTHandle _baseStarBlurredRT1;
        private RTHandle _baseStarBlurredRT2;
        private RTHandle[] _starRTs = new RTHandle[8];

        public RTHandle _ScaledRT => _scaledRT;
        public RTHandle _BrightRT => _brightRT;
        public RTHandle _BaseStarBlurredRT1 => _baseStarBlurredRT1;
        public RTHandle _BaseStarBlurredRT2 => _baseStarBlurredRT2;
        public RTHandle[] _StarRTs => _starRTs;

        public RenderTextureDescriptor _brightRTD { get; private set; }

        private int _w = 0;
        private int _h = 0;
        private readonly Color[] meshColors = new Color[4] { Color.white, Color.white, Color.white, Color.white };
        private readonly Vector2[] meshUVS = new Vector2[4] { Vector2.zero, Vector2.up, Vector2.one, Vector2.right };
        private readonly int[] meshIndices = new int[4] { 0, 1, 2, 3 };

        public Mesh _brightnessExtractionMesh = new Mesh();

        public void Setup(RenderTextureDescriptor rtd)
        {
            int width = rtd.width;
            int height = rtd.height;

            int scaledW = width / 4;
            int scaledH = height / 4;
            int brightW = scaledW + 2;
            int brightH = scaledH + 2;

            RenderTextureDescriptor scaleRTD = new RenderTextureDescriptor(scaledW, scaledH, GraphicsFormat.R16G16B16A16_SFloat, 0);
            _brightRTD = new RenderTextureDescriptor(brightW, brightH, GraphicsFormat.R8G8B8A8_SNorm, depthBufferBits: 0);

            RenderingUtils.ReAllocateHandleIfNeeded(ref _scaledRT, scaleRTD, name: nameof(_scaledRT));
            RenderingUtils.ReAllocateHandleIfNeeded(ref _brightRT, _brightRTD, FilterMode.Bilinear, name: nameof(_brightRT));
            RenderingUtils.ReAllocateHandleIfNeeded(ref _baseStarBlurredRT1, _brightRTD, name: nameof(_baseStarBlurredRT1));
            RenderingUtils.ReAllocateHandleIfNeeded(ref _baseStarBlurredRT2, _brightRTD, name: nameof(_baseStarBlurredRT2));
            for (int i = 0; i < _starRTs.Length; ++i)
            {
                RenderingUtils.ReAllocateHandleIfNeeded(ref _starRTs[i], scaleRTD, name: $"{nameof(_starRTs)}[{i}]");
            }

            if (_IsResolutionChanged(width, height))
            {
                _UpdateMesh(_brightnessExtractionMesh, scaledW, scaledH, 2, 2);
            }
            _brightnessExtractionMesh.MarkDynamic();
        }

        public void Dispose()
        {
            RTHandles.Release(_scaledRT);
            RTHandles.Release(_brightRT);
            RTHandles.Release(_baseStarBlurredRT1);
            RTHandles.Release(_baseStarBlurredRT2);
            for (int i = 0; i < _starRTs.Length; ++i)
            {
                RTHandles.Release(_starRTs[i]);
            }
        }

        private bool _IsResolutionChanged(int w, int h)
        {
            if (w != _w)
            {
                _w = w;
                _h = h;
                return true;
            }

            if (h != _h)
            {
                _w = w;
                _h = h;
                return true;
            }

            return false;
        }

        private void _UpdateMesh(Mesh m, int scaledW, int scaledH, int offsetX, int offsetY)
        {
            m.Clear();
            int w = scaledW + offsetX;
            int h = scaledH + offsetY;

            int halfOffsetX = offsetX / 2;
            int halfOffsetY = offsetY / 2;

            float x0 = (float)halfOffsetX / w;
            float x1 = (float)(w - halfOffsetX) / w;
            float y0 = (float)halfOffsetY / h;
            float y1 = (float)(h - halfOffsetX) / h;

            Vector3[] vertices = new Vector3[4]{
                new(x0, y0, 0),
                new(x0, y1, 0),
                new(x1, y1, 0),
                new(x1, y0, 0)
            };

            m.SetVertices(vertices);
            m.SetColors(meshColors);
            m.SetUVs(0, meshUVS);
            m.SetIndices(meshIndices, MeshTopology.Quads, 0);
            m.UploadMeshData(markNoLongerReadable: false);
        }
    }


    // ========================================================================================================================================
    private class PassData
    {
        public TextureHandle TexHandle_SrcColor;
        public TextureHandle TexHandle_Scaled;
        public TextureHandle TexHandle_Bright;
        public TextureHandle TexHandle_BaseStarBlurred1;
        public TextureHandle TexHandle_BaseStarBlurred2;
        public TextureHandle[] TexHandle_Stars;
        public Material Mat_Bloom;
        public Material Mat_DualFilter;
        public float BrightRTD_Width;
        public float BrightRTD_Height;
    }

    // ========================================================================================================================================
    private class CrossFilter_RenderPass : ScriptableRenderPass, IDisposable
    {
        private CrossFilter_RenderPassSettings _settings;

        private const string RENDER_TAG = nameof(CrossFilter_RenderPass);

        private const int RAY_MAX_PASSES = 3;
        private const int RAY_SAMPLES = 8;
        private readonly Matrix4x4 P = Matrix4x4.Ortho(0, 1, 0, 1, 0, 1);
        private readonly Matrix4x4 V = Matrix4x4.identity;
        private readonly Color COLOR_WHITE = new Color(0.63f, 0.63f, 0.63f, 0);
        private readonly Color[] COLOR_ChromaticAberration = new Color[8] {
            new(0.5f, 0.5f, 0.5f, 0),
            new(0.8f, 0.3f, 0.3f, 0),
            new(1.0f, 0.2f, 0.2f, 0),
            new(0.5f, 0.2f, 0.6f, 0),
            new(0.2f, 0.2f, 1.0f, 0),
            new(0.2f, 0.3f, 0.7f, 0),
            new(0.2f, 0.6f, 0.2f, 0),
            new(0.3f, 0.5f, 0.3f, 0),
        };
        private static readonly ProfilingSampler PS_ExtractBright = new ProfilingSampler(nameof(PS_ExtractBright));
        private static readonly ProfilingSampler PS_BlurBright = new ProfilingSampler(nameof(PS_BlurBright));
        private static readonly ProfilingSampler PS_MakeStarRay = new ProfilingSampler(nameof(PS_MakeStarRay));
        private static readonly ProfilingSampler PS_CombineBloom = new ProfilingSampler(nameof(PS_CombineBloom));

        private static Color[,] _rayColors = new Color[RAY_MAX_PASSES, RAY_SAMPLES];

        private Material _materialBloom;
        private Material _materialDualFilter;
        private RTCollection _rtc = new RTCollection();

        public CrossFilter_RenderPass(CrossFilter_RenderPassSettings settings)
        {
            _settings = settings;
            if (_materialBloom == null)
            {
                _materialBloom = CoreUtils.CreateEngineMaterial("srp/CrossFilter_Bloom");
            }
            if (_materialDualFilter == null)
            {
                _materialDualFilter = CoreUtils.CreateEngineMaterial("srp/CrossFilter_Filter");
            }

            _FillStarRayColors(_rayColors);
            requiresIntermediateTexture = true;
        }

        public void Dispose()
        {
            _rtc.Dispose();
        }

        internal void Setup(RenderTextureDescriptor desc)
        {
            _rtc.Setup(desc);
        }

        private void _FillStarRayColors(Color[,] rayColors)
        {
            for (int p = 0; p < RAY_MAX_PASSES; p++)
            {
                float ratio = (float)(p + 1) / RAY_MAX_PASSES;
                for (int s = 0; s < RAY_SAMPLES; s++)
                {
                    Color chromaticAberrColor = Color.Lerp(COLOR_ChromaticAberration[s], COLOR_WHITE, ratio);
                    rayColors[p, s] = Color.Lerp(COLOR_WHITE, chromaticAberrColor, 0.7f);
                }
            }
        }

        public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
        {
            string passName = "Unsafe Pass";

            UniversalCameraData cameraData = frameData.Get<UniversalCameraData>();
            if (cameraData.camera.cameraType != CameraType.Game)
            {
                return;
            }

            using (IUnsafeRenderGraphBuilder builder = renderGraph.AddUnsafePass(passName, out PassData passData))
            {
                UniversalResourceData resourceData = frameData.Get<UniversalResourceData>();

                passData.TexHandle_SrcColor = resourceData.activeColorTexture;
                passData.TexHandle_Scaled = renderGraph.ImportTexture(_rtc._ScaledRT);
                passData.TexHandle_Bright = renderGraph.ImportTexture(_rtc._BrightRT);
                passData.TexHandle_BaseStarBlurred1 = renderGraph.ImportTexture(_rtc._BaseStarBlurredRT1);
                passData.TexHandle_BaseStarBlurred2 = renderGraph.ImportTexture(_rtc._BaseStarBlurredRT2);
                passData.TexHandle_Stars = new TextureHandle[8];
                for (int i = 0; i < 8; i++)
                {
                    passData.TexHandle_Stars[i] = renderGraph.ImportTexture(_rtc._StarRTs[i]);
                }
                passData.Mat_Bloom = _materialBloom;
                passData.Mat_DualFilter = _materialDualFilter;
                passData.BrightRTD_Width = _rtc._brightRTD.width;
                passData.BrightRTD_Height = _rtc._brightRTD.height;


                builder.UseTexture(passData.TexHandle_SrcColor);
                builder.UseTexture(passData.TexHandle_Scaled, AccessFlags.Write);
                builder.UseTexture(passData.TexHandle_Bright, AccessFlags.ReadWrite);
                builder.UseTexture(passData.TexHandle_BaseStarBlurred1, AccessFlags.ReadWrite);
                builder.UseTexture(passData.TexHandle_BaseStarBlurred2, AccessFlags.ReadWrite);
                for (int i = 0; i < 8; ++i)
                {
                    builder.UseTexture(passData.TexHandle_Stars[i], AccessFlags.ReadWrite);
                }
                builder.AllowPassCulling(value: false);
                builder.SetRenderFunc<PassData>(ExecutePass);
            }
        }

        private static void ExecutePass(PassData passData, UnsafeGraphContext context)
        {
            Vector4 scaleBias = new Vector4(1, 1, 0, 0);

            UnsafeCommandBuffer cmd = context.cmd;
            CommandBuffer nativeCmd = CommandBufferHelpers.GetNativeCommandBuffer(context.cmd);

            cmd.SetRenderTarget(passData.TexHandle_Scaled);
            Blitter.BlitTexture(nativeCmd, passData.TexHandle_SrcColor, scaleBias, mipLevel: 0, bilinear: false);


            using (new ProfilingScope(cmd, PS_ExtractBright))
            {
                // cmd.SetProjectionMatrix(P);
                // cmd.SetViewMatrix(V);
                // cmd.SetRenderTarget(_rtc._BrightRT);
                // cmd.SetGlobalTexture(_rtc._BlitTexture, _rtc._ScaledRT);
                // cmd.DrawMesh(_rtc._brightnessExtractionMesh, Matrix4x4.identity, _materialBloom, 0, RTCollection.PASS_BLOOM_THRESHOLD);

                Blitter.BlitTexture(nativeCmd, passData.TexHandle_SrcColor, passData.TexHandle_Bright, passData.Mat_Bloom, RTCollection.PASS_BLOOM_THRESHOLD);
            }

            // Blitter.BlitCameraTexture(cmd, _rtc._BrightRT, _cameraColorTargetHandle); // test blit

            using (new ProfilingScope(cmd, PS_BlurBright))
            {
                Blitter.BlitTexture(nativeCmd, passData.TexHandle_Bright, passData.TexHandle_BaseStarBlurred1, passData.Mat_DualFilter, RTCollection.PASS_CROSSFILTER_GAUSSIAN_VERT);
                Blitter.BlitTexture(nativeCmd, passData.TexHandle_BaseStarBlurred1, passData.TexHandle_BaseStarBlurred2, passData.Mat_DualFilter, RTCollection.PASS_CROSSFILTER_GAUSSIAN_HORIZ);
            }

            TextureHandle _BloomBlurRT;
            using (new ProfilingScope(cmd, PS_MakeStarRay))
            {
                _BloomBlurRT = _MakeStarRayTex(nativeCmd, passData);
            }
            // Blitter.BlitCameraTexture(cmd, _BloomBlurRT, _cameraColorTargetHandle); // test blit

            using (new ProfilingScope(cmd, PS_CombineBloom))
            {
                cmd.SetRenderTarget(passData.TexHandle_SrcColor);
                cmd.SetGlobalTexture("_BloomBlurTex", _BloomBlurRT);
                Blitter.BlitTexture(nativeCmd, passData.TexHandle_Scaled, scaleBias, passData.Mat_Bloom, RTCollection.PASS_BLOOM_COMPOSITE);
            }
        }

        private static TextureHandle _MakeStarRayTex(CommandBuffer nativeCmd, PassData data)
        {
            Vector4 scaleBias = new Vector4(1, 1, 0, 0);
            TextureHandle baseStarBlurredRT = data.TexHandle_BaseStarBlurred2;

            float srcW = data.BrightRTD_Width;
            float srcH = data.BrightRTD_Height;
            float worldRotY = Mathf.PI / 2;
            float radOffset = worldRotY / 5;

            int starRayCount = 6;// 광선의 줄기 개수

            for (int d = 0; d < starRayCount; d++)
            {
                TextureHandle srcRT = baseStarBlurredRT;
                float rad = radOffset + 2 * Mathf.PI * ((float)d / starRayCount);
                float sin = Mathf.Sin(rad);
                float cos = Mathf.Cos(rad);
                Vector2 stepUV = new Vector2(0.15f * sin / srcW, 0.15f * cos / srcH);
                float attnPowScale = (Mathf.Atan(Mathf.PI / 4) + 0.1f) * (160.0f + 120.0f) / (srcW + srcH);

                int workingTexureIndex = 0;
                for (int p = 0; p < RAY_MAX_PASSES; p++)
                {
                    TextureHandle destRT;
                    if (p == RAY_MAX_PASSES - 1)
                    {
                        destRT = data.TexHandle_Stars[d + 2];
                    }
                    else
                    {
                        destRT = data.TexHandle_Stars[workingTexureIndex];
                    }

                    Vector4[] avSampleWeights = new Vector4[RAY_SAMPLES]; // xyzw
                    Vector4[] avSampleOffsets = new Vector4[RAY_SAMPLES]; // xy
                    for (int i = 0; i < RAY_SAMPLES; i++)
                    {
                        avSampleOffsets[i].x = stepUV.x * i;
                        avSampleOffsets[i].y = stepUV.y * i;

                        float lum = Mathf.Pow(0.95f, attnPowScale * i);
                        avSampleWeights[i] = _rayColors[RAY_MAX_PASSES - 1 - p, i] * lum * (p + 1.0f) * 0.5f;

                        if (Mathf.Abs(avSampleOffsets[i].x) >= 0.9f
                            || Mathf.Abs(avSampleOffsets[i].y) >= 0.9f)
                        {
                            avSampleOffsets[i].x = 0;
                            avSampleOffsets[i].y = 0;
                            avSampleWeights[i] = Vector4.zero;
                        }
                    }

                    nativeCmd.SetGlobalVectorArray("_avSampleOffsets", avSampleOffsets);
                    nativeCmd.SetGlobalVectorArray("_avSampleWeights", avSampleWeights);
                    Blitter.BlitTexture(nativeCmd, srcRT, destRT, data.Mat_DualFilter, RTCollection.PASS_CROSSFILTER_STAR_RAY);


                    stepUV *= RAY_SAMPLES;
                    attnPowScale *= RAY_SAMPLES;
                    srcRT = data.TexHandle_Stars[workingTexureIndex];
                    workingTexureIndex ^= 1;
                }
            }

            // 합성.
            nativeCmd.SetGlobalTexture(RTCollection._StarTexs[0 + 2], data.TexHandle_Stars[0 + 2]);
            nativeCmd.SetGlobalTexture(RTCollection._StarTexs[1 + 2], data.TexHandle_Stars[1 + 2]);
            nativeCmd.SetGlobalTexture(RTCollection._StarTexs[2 + 2], data.TexHandle_Stars[2 + 2]);
            nativeCmd.SetGlobalTexture(RTCollection._StarTexs[3 + 2], data.TexHandle_Stars[3 + 2]);
            nativeCmd.SetGlobalTexture(RTCollection._StarTexs[4 + 2], data.TexHandle_Stars[4 + 2]);
            nativeCmd.SetGlobalTexture(RTCollection._StarTexs[5 + 2], data.TexHandle_Stars[5 + 2]);
            Blitter.BlitCameraTexture(nativeCmd, data.TexHandle_Stars[1], data.TexHandle_Stars[0], data.Mat_DualFilter, RTCollection.PASS_CROSSFILTER_MERGE_STAR);

            return data.TexHandle_Stars[0];
        }
    }
}
