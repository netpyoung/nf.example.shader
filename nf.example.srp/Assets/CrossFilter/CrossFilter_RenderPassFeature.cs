using System;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
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
            _pass.Setup(renderer.cameraColorTargetHandle);
        }
    }

    // ====================================================================
    // ====================================================================
    [Serializable]
    public struct CrossFilter_RenderPassSettings
    {
    }

    // ====================================================================
    // ====================================================================
    class RTCollection
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
        public readonly int[] _StarTexs = new int[8] {
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
        public RTHandle _ScaledRT => _scaledRT;
        private RTHandle _brightRT;
        public RTHandle _BrightRT => _brightRT;
        private RTHandle _baseStarBlurredRT1;
        public RTHandle _BaseStarBlurredRT1 => _baseStarBlurredRT1;
        private RTHandle _baseStarBlurredRT2;
        public RTHandle _BaseStarBlurredRT2 => _baseStarBlurredRT2;
        private RTHandle[] _starRTs = new RTHandle[8];
        public RTHandle[] _StarRTs => _starRTs;

        public  RenderTextureDescriptor _brightRTD { get; private set; }
        private int _w = 0;
        private int _h = 0;
        readonly Color[] meshColors = new Color[4] { Color.white, Color.white, Color.white, Color.white };
        readonly Vector2[] meshUVS = new Vector2[4] { Vector2.zero, Vector2.up, Vector2.one, Vector2.right };
        readonly int[] meshIndices = new int[4] { 0, 1, 2, 3 };
        public Mesh _brightnessExtractionMesh = new Mesh();
        public MaterialPropertyBlock _PropertyBlock = new MaterialPropertyBlock();

        internal void Setup(RenderTextureDescriptor rtd)
        {
            int width = rtd.width;
            int height = rtd.height;

            int scaledW = width / 4;
            int scaledH = height / 4;
            int brightW = scaledW + 2;
            int brightH = scaledH + 2;


            RenderTextureDescriptor scaleRTD = new RenderTextureDescriptor(scaledW, scaledH, GraphicsFormat.R16G16B16A16_SFloat, 0);
            _brightRTD = new RenderTextureDescriptor(brightW, brightH, GraphicsFormat.R8G8B8A8_SNorm, depthBufferBits: 0);

            if (_IsResolutionChanged(width, height))
            {
                _UpdateMesh(_brightnessExtractionMesh, scaledW, scaledH, 2, 2);
            }

            RenderingUtils.ReAllocateIfNeeded(ref _scaledRT, scaleRTD);
            RenderingUtils.ReAllocateIfNeeded(ref _brightRT, _brightRTD, FilterMode.Bilinear);
            RenderingUtils.ReAllocateIfNeeded(ref _baseStarBlurredRT1, _brightRTD);
            RenderingUtils.ReAllocateIfNeeded(ref _baseStarBlurredRT2, _brightRTD);

            for (int i = 0; i < _starRTs.Length; ++i)
            {
                RenderingUtils.ReAllocateIfNeeded(ref _starRTs[i], scaleRTD);
            }

            // 
            _brightnessExtractionMesh.MarkDynamic();
        }

        public void Cleanup()
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

        bool _IsResolutionChanged(int w, int h)
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

    // ====================================================================
    // ====================================================================
    private class CrossFilter_RenderPass : ScriptableRenderPass
    {
        private CrossFilter_RenderPassSettings _settings;

        const string RENDER_TAG = nameof(CrossFilter_RenderPass);

        const int RAY_MAX_PASSES = 3;
        const int RAY_SAMPLES = 8;
        readonly Matrix4x4 P = Matrix4x4.Ortho(0, 1, 0, 1, 0, 1);
        readonly Matrix4x4 V = Matrix4x4.identity;
        readonly Color COLOR_WHITE = new Color(0.63f, 0.63f, 0.63f, 0);
        readonly Color[] COLOR_ChromaticAberration = new Color[8] {
            new(0.5f, 0.5f, 0.5f, 0),
            new(0.8f, 0.3f, 0.3f, 0),
            new(1.0f, 0.2f, 0.2f, 0),
            new(0.5f, 0.2f, 0.6f, 0),
            new(0.2f, 0.2f, 1.0f, 0),
            new(0.2f, 0.3f, 0.7f, 0),
            new(0.2f, 0.6f, 0.2f, 0),
            new(0.3f, 0.5f, 0.3f, 0),
        };
        readonly ProfilingSampler PS_ExtractBright = new ProfilingSampler(nameof(PS_ExtractBright));
        readonly ProfilingSampler PS_BlurBright = new ProfilingSampler(nameof(PS_BlurBright));
        readonly ProfilingSampler PS_MakeStarRay = new ProfilingSampler(nameof(PS_MakeStarRay));
        readonly ProfilingSampler PS_CombineBloom = new ProfilingSampler(nameof(PS_CombineBloom));

        private Color[,] _rayColors = new Color[RAY_MAX_PASSES, RAY_SAMPLES];

        private Material _materialBloom;
        private Material _materialDualFilter;
        private RTHandle _cameraColorTargetHandle;
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
        }

        ~CrossFilter_RenderPass()
        {
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            _rtc.Setup(renderingData.cameraData.cameraTargetDescriptor);
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            _rtc.Cleanup();
        }

        internal void Setup(RTHandle cameraColorTargetHandle)
        {
            _cameraColorTargetHandle = cameraColorTargetHandle;
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

        RTHandle _MakeStarRayTex(CommandBuffer cmd, RTHandle baseStarBlurredRT)
        {
            float srcW = _rtc._brightRTD.width;
            float srcH = _rtc._brightRTD.height;
            float worldRotY = Mathf.PI / 2;
            float radOffset = worldRotY / 5;

            int starRayCount = 6;// 광선의 줄기 개수

            for (int d = 0; d < starRayCount; d++)
            {
                RTHandle srcRT = baseStarBlurredRT;
                float rad = radOffset + 2 * Mathf.PI * ((float)d / starRayCount);
                float sin = Mathf.Sin(rad);
                float cos = Mathf.Cos(rad);
                Vector2 stepUV = new Vector2(0.15f * sin / srcW, 0.15f * cos / srcH);
                float attnPowScale = (Mathf.Atan(Mathf.PI / 4) + 0.1f) * (160.0f + 120.0f) / (srcW + srcH);

                int workingTexureIndex = 0;
                for (int p = 0; p < RAY_MAX_PASSES; p++)
                {
                    RTHandle destRT;
                    if (p == RAY_MAX_PASSES - 1)
                    {
                        destRT = _rtc._StarRTs[d + 2];
                    }
                    else
                    {
                        destRT = _rtc._StarRTs[workingTexureIndex];
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

                    cmd.SetGlobalVectorArray("_avSampleOffsets", avSampleOffsets);
                    cmd.SetGlobalVectorArray("_avSampleWeights", avSampleWeights);
                    cmd.SetGlobalTexture(_rtc._BlitTexture, srcRT);
                    Blitter.BlitCameraTexture(cmd, srcRT, destRT, _materialDualFilter, RTCollection.PASS_CROSSFILTER_STAR_RAY);

                    stepUV *= RAY_SAMPLES;
                    attnPowScale *= RAY_SAMPLES;
                    srcRT = _rtc._StarRTs[workingTexureIndex];
                    workingTexureIndex ^= 1;
                }
            }

            // 합성.
            cmd.SetGlobalTexture(_rtc._StarTexs[0 + 2], _rtc._StarRTs[0 + 2]);
            cmd.SetGlobalTexture(_rtc._StarTexs[1 + 2], _rtc._StarRTs[1 + 2]);
            cmd.SetGlobalTexture(_rtc._StarTexs[2 + 2], _rtc._StarRTs[2 + 2]);
            cmd.SetGlobalTexture(_rtc._StarTexs[3 + 2], _rtc._StarRTs[3 + 2]);
            cmd.SetGlobalTexture(_rtc._StarTexs[4 + 2], _rtc._StarRTs[4 + 2]);
            cmd.SetGlobalTexture(_rtc._StarTexs[5 + 2], _rtc._StarRTs[5 + 2]);
            Blitter.BlitCameraTexture(cmd, _rtc._StarRTs[1], _rtc._StarRTs[0], _materialDualFilter, RTCollection.PASS_CROSSFILTER_MERGE_STAR);

            return _rtc._StarRTs[0];
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CameraData cameraData = renderingData.cameraData;
            if (cameraData.camera.cameraType != CameraType.Game)
            {
                return;
            }

            CommandBuffer cmd = CommandBufferPool.Get(RENDER_TAG);
            Blitter.BlitCameraTexture(cmd, _cameraColorTargetHandle, _rtc._ScaledRT);

            using (new ProfilingScope(cmd, PS_ExtractBright))
            {
                // cmd.SetProjectionMatrix(P);
                // cmd.SetViewMatrix(V);
                // cmd.SetRenderTarget(_rtc._BrightRT);
                // cmd.SetGlobalTexture(_rtc._BlitTexture, _rtc._ScaledRT);
                // cmd.DrawMesh(_rtc._brightnessExtractionMesh, Matrix4x4.identity, _materialBloom, 0, RTCollection.PASS_BLOOM_THRESHOLD);
                Blitter.BlitCameraTexture(cmd, _rtc._ScaledRT, _rtc._BrightRT, _materialBloom, RTCollection.PASS_BLOOM_THRESHOLD);
            }

            // Blitter.BlitCameraTexture(cmd, _rtc._BrightRT, _cameraColorTargetHandle); // test blit

            using (new ProfilingScope(cmd, PS_BlurBright))
            {
                cmd.SetGlobalTexture(_rtc._BlitTexture, _rtc._BrightRT);
                Blitter.BlitCameraTexture(cmd, _rtc._BrightRT, _rtc._BaseStarBlurredRT1, _materialDualFilter, RTCollection.PASS_CROSSFILTER_GAUSSIAN_VERT);

                cmd.SetGlobalTexture(_rtc._BlitTexture, _rtc._BaseStarBlurredRT1);
                Blitter.BlitCameraTexture(cmd, _rtc._BaseStarBlurredRT1, _rtc._BaseStarBlurredRT2, _materialDualFilter, RTCollection.PASS_CROSSFILTER_GAUSSIAN_HORIZ);
            }

            RTHandle _BloomBlurRT;
            using (new ProfilingScope(cmd, PS_MakeStarRay))
            {
                _BloomBlurRT = _MakeStarRayTex(cmd, _rtc._BaseStarBlurredRT2);
            }
            // Blitter.BlitCameraTexture(cmd, _BloomBlurRT, _cameraColorTargetHandle); // test blit

            using (new ProfilingScope(cmd, PS_CombineBloom))
            {
                cmd.SetGlobalTexture(_rtc._BlitTexture, _rtc._ScaledRT);
                cmd.SetGlobalTexture("_BloomBlurTex", _BloomBlurRT);
                Blitter.BlitCameraTexture(cmd, _rtc._ScaledRT, _cameraColorTargetHandle, _materialBloom, RTCollection.PASS_BLOOM_COMPOSITE);
            }

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }
}
