using System;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class CrossFilter_RenderPassFeature : ScriptableRendererFeature
{
    [Serializable]
    public struct CrossFilter_RenderPassSettings
    {
    }

    class CrossFilter_RenderPass : ScriptableRenderPass
    {
        CrossFilter_RenderPassSettings _settings;

        const string RENDER_TAG = nameof(CrossFilter_RenderPass);

        const int PASS_BLOOM_THRESHOLD = 0;
        const int PASS_BLOOM_COMPOSITE = 1;

        const int PASS_CROSSFILTER_GAUSSIAN_VERT = 0;
        const int PASS_CROSSFILTER_GAUSSIAN_HORIZ = 1;
        const int PASS_CROSSFILTER_STAR_RAY = 2;
        const int PASS_CROSSFILTER_MERGE_STAR = 3;

        const int RAY_MAX_PASSES = 3;
        const int RAY_SAMPLES = 8;

        readonly int _MainTex = Shader.PropertyToID("_MainTex");
        readonly int _ScaledTex = Shader.PropertyToID("_ScaledTex");
        readonly int _BrightTex = Shader.PropertyToID("_BrightTex");
        readonly int _BaseStarBlurredTex1 = Shader.PropertyToID("_BaseStarBlurredTex1");
        readonly int _BaseStarBlurredTex2 = Shader.PropertyToID("_BaseStarBlurredTex2");
        readonly int[] _StarTexs = new int[8] {
            Shader.PropertyToID("_StarTex0"),
            Shader.PropertyToID("_StarTex1"),
            Shader.PropertyToID("_StarTex2"),
            Shader.PropertyToID("_StarTex3"),
            Shader.PropertyToID("_StarTex4"),
            Shader.PropertyToID("_StarTex5"),
            Shader.PropertyToID("_StarTex6"),
            Shader.PropertyToID("_StarTex7"),
        };

        readonly Matrix4x4 P = Matrix4x4.Ortho(0, 1, 0, 1, 0, 1);
        readonly Matrix4x4 V = Matrix4x4.identity;
        readonly Color COLOR_WHITE = new Color(0.63f, 0.63f, 0.63f, 0);
        readonly Color[] COLOR_ChromaticAberration = new Color[8] {
            new Color(0.5f, 0.5f, 0.5f, 0),
            new Color(0.8f, 0.3f, 0.3f, 0),
            new Color(1.0f, 0.2f, 0.2f, 0),
            new Color(0.5f, 0.2f, 0.6f, 0),
            new Color(0.2f, 0.2f, 1.0f, 0),
            new Color(0.2f, 0.3f, 0.7f, 0),
            new Color(0.2f, 0.6f, 0.2f, 0),
            new Color(0.3f, 0.5f, 0.3f, 0),
        };
        readonly Color[] meshColors = new Color[4] { Color.white, Color.white, Color.white, Color.white };
        readonly Vector2[] meshUVS = new Vector2[4] { Vector2.zero, Vector2.up, Vector2.one, Vector2.right };
        readonly int[] meshIndices = new int[4] { 0, 1, 2, 3 };

        readonly ProfilingSampler PS_ExtractBright = new ProfilingSampler(nameof(PS_ExtractBright));
        readonly ProfilingSampler PS_BlurBright = new ProfilingSampler(nameof(PS_BlurBright));
        readonly ProfilingSampler PS_MakeStarRay = new ProfilingSampler(nameof(PS_MakeStarRay));
        readonly ProfilingSampler PS_CombineBloom = new ProfilingSampler(nameof(PS_CombineBloom));

        Mesh _brightnessExtractionMesh = new Mesh();
        Material _materialBloom;
        Material _materialDualFilter;
        RenderTargetIdentifier _sourceRTI;
        RenderTextureDescriptor _brightRTD;
        int _w = 0;
        int _h = 0;
        Color[,] _rayColors = new Color[RAY_MAX_PASSES, RAY_SAMPLES];

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
            _brightnessExtractionMesh.MarkDynamic();

            FillStarRayColors(_rayColors);
        }

        void FillStarRayColors(Color[,] rayColors)
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

        void UpdateMesh(Mesh m, int scaledW, int scaledH, int offsetX, int offsetY)
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

            m.SetVertices(new Vector3[4]{
                new Vector3(x0, y0, 0),
                new Vector3(x0, y1, 0),
                new Vector3(x1, y1, 0),
                new Vector3(x1, y0, 0)
            });
            m.SetColors(meshColors);
            m.SetUVs(0, meshUVS);
            m.SetIndices(meshIndices, MeshTopology.Quads, 0);
            m.UploadMeshData(false);
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            this._sourceRTI = renderingData.cameraData.renderer.cameraColorTarget;

            var width = renderingData.cameraData.camera.pixelWidth;
            var height = renderingData.cameraData.camera.pixelHeight;

            int scaledW = width / 4;
            int scaledH = height / 4;
            int brightW = scaledW + 2;
            int brightH = scaledH + 2;

            _brightRTD = new RenderTextureDescriptor(brightW, brightH)
            {
                depthBufferBits = 0,
                graphicsFormat = GraphicsFormat.R8G8B8A8_SNorm
            };

            if (IsResolutionChanged(width, height))
            {
                UpdateMesh(_brightnessExtractionMesh, scaledW, scaledH, 2, 2);
            }

            cmd.GetTemporaryRT(_ScaledTex, scaledW, scaledH, 0, FilterMode.Bilinear, GraphicsFormat.R16G16B16A16_SFloat);
            cmd.GetTemporaryRT(_BrightTex, _brightRTD, FilterMode.Bilinear);
            cmd.GetTemporaryRT(_BaseStarBlurredTex1, brightW, brightH, 0, FilterMode.Bilinear, GraphicsFormat.R8G8B8A8_SNorm);
            cmd.GetTemporaryRT(_BaseStarBlurredTex2, brightW, brightH, 0, FilterMode.Bilinear, GraphicsFormat.R8G8B8A8_SNorm);

            for (int i = 0; i < _StarTexs.Length; ++i)
            {
                cmd.GetTemporaryRT(_StarTexs[i], scaledW, scaledH, 0, FilterMode.Bilinear, GraphicsFormat.R8G8B8A8_SNorm);
            }

            cmd.SetRenderTarget(_BrightTex);
            cmd.ClearRenderTarget(false, true, Color.black);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.isSceneViewCamera)
            {
                return;
            }

            CommandBuffer cmd = CommandBufferPool.Get(RENDER_TAG);

            cmd.Blit(_sourceRTI, _ScaledTex);

            using (new ProfilingScope(cmd, PS_ExtractBright))
            {
                cmd.SetProjectionMatrix(P);
                cmd.SetViewMatrix(V);
                cmd.SetRenderTarget(_BrightTex);
                cmd.SetGlobalTexture(_MainTex, _ScaledTex);
                cmd.DrawMesh(_brightnessExtractionMesh, Matrix4x4.identity, _materialBloom, 0, PASS_BLOOM_THRESHOLD);
            }

            using (new ProfilingScope(cmd, PS_BlurBright))
            {
                cmd.SetGlobalTexture(_MainTex, _BrightTex);
                cmd.Blit(_BrightTex, _BaseStarBlurredTex1, _materialDualFilter, PASS_CROSSFILTER_GAUSSIAN_VERT);
                cmd.SetGlobalTexture(_MainTex, _BaseStarBlurredTex1);
                cmd.Blit(_BaseStarBlurredTex1, _BaseStarBlurredTex2, _materialDualFilter, PASS_CROSSFILTER_GAUSSIAN_HORIZ);
            }

            int _BloomBlurTex;
            using (new ProfilingScope(cmd, PS_MakeStarRay))
            {
                _BloomBlurTex = MakeStarRay(cmd, _BaseStarBlurredTex2);
            }

            using (new ProfilingScope(cmd, PS_CombineBloom))
            {
                cmd.SetGlobalTexture(_MainTex, _ScaledTex);
                cmd.SetGlobalTexture("_BloomBlurTex", _BloomBlurTex);
                cmd.Blit(_ScaledTex, _sourceRTI, _materialBloom, PASS_BLOOM_COMPOSITE);
            }

            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }

        bool IsResolutionChanged(int w, int h)
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

        int MakeStarRay(CommandBuffer cmd, int baseStarBlurredTex)
        {
            float srcW = _brightRTD.width;
            float srcH = _brightRTD.height;
            float worldRotY = Mathf.PI / 2;
            float radOffset = worldRotY / 5;

            int starRayCount = 6;// 광선의 줄기 개수

            for (int d = 0; d < starRayCount; d++)
            {
                int srcTex = baseStarBlurredTex;
                float rad = radOffset + (2 * Mathf.PI) * ((float)d / starRayCount);
                float sin = Mathf.Sin(rad);
                float cos = Mathf.Cos(rad);
                Vector2 stepUV = new Vector2(0.15f * sin / srcW, 0.15f * cos / srcH);
                float attnPowScale = (Mathf.Atan(Mathf.PI / 4) + 0.1f) * (160.0f + 120.0f) / (srcW + srcH);

                int workingTexureIndex = 0;
                for (int p = 0; p < RAY_MAX_PASSES; p++)
                {
                    int destTex;
                    if (p == RAY_MAX_PASSES - 1)
                    {
                        destTex = _StarTexs[d + 2];
                    }
                    else
                    {
                        destTex = _StarTexs[workingTexureIndex];
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
                    cmd.SetGlobalTexture(_MainTex, srcTex);
                    cmd.Blit(srcTex, destTex, _materialDualFilter, PASS_CROSSFILTER_STAR_RAY);

                    stepUV *= RAY_SAMPLES;
                    attnPowScale *= RAY_SAMPLES;
                    srcTex = _StarTexs[workingTexureIndex];
                    workingTexureIndex ^= 1;
                }
            }

            // 합성.
            cmd.SetGlobalTexture(_StarTexs[0 + 2], _StarTexs[0 + 2]);
            cmd.SetGlobalTexture(_StarTexs[1 + 2], _StarTexs[1 + 2]);
            cmd.SetGlobalTexture(_StarTexs[2 + 2], _StarTexs[2 + 2]);
            cmd.SetGlobalTexture(_StarTexs[3 + 2], _StarTexs[3 + 2]);
            cmd.SetGlobalTexture(_StarTexs[4 + 2], _StarTexs[4 + 2]);
            cmd.SetGlobalTexture(_StarTexs[5 + 2], _StarTexs[5 + 2]);
            cmd.Blit(_StarTexs[1], _StarTexs[0], _materialDualFilter, PASS_CROSSFILTER_MERGE_STAR);

            return _StarTexs[0];
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(_ScaledTex);
            cmd.ReleaseTemporaryRT(_BrightTex);
            cmd.ReleaseTemporaryRT(_BaseStarBlurredTex1);
            cmd.ReleaseTemporaryRT(_BaseStarBlurredTex2);

            for (int i = 0; i < _StarTexs.Length; ++i)
            {
                cmd.ReleaseTemporaryRT(_StarTexs[i]);
            }
        }
    }

    [SerializeField]
    CrossFilter_RenderPassSettings settings;
    CrossFilter_RenderPass _pass;

    public override void Create()
    {
        _pass = new CrossFilter_RenderPass(settings);
        _pass.renderPassEvent = RenderPassEvent.AfterRendering;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(_pass);
    }
}
