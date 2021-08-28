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
        [Range(0, 7)] public int _Index;
    }

    class CrossFilter_RenderPass : ScriptableRenderPass
    {
        CrossFilter_RenderPassSettings _settings;
        const string RENDER_TAG = nameof(CrossFilter_RenderPass);

        const int PASS_BLOOM_THRESHOLD = 0;
        const int PASS_BLOOM_COMBINE = 1;

        const int PASS_DUALFILTER_DOWN = 0;
        const int PASS_DUALFILTER_UP = 1;

        Material _materialBloom;
        Material _materialDualFilter;

        RenderTargetIdentifier _sourceRTI;

        readonly static int _ScaledTex = Shader.PropertyToID("_ScaledTex");
        readonly static int _BrightTex = Shader.PropertyToID("_BrightTex");
        readonly static int _BaseStarBlurredTex1 = Shader.PropertyToID("_BaseStarBlurredTex1");
        readonly static int _BaseStarBlurredTex2 = Shader.PropertyToID("_BaseStarBlurredTex2");

        readonly static int _MainTex = Shader.PropertyToID("_MainTex");

        Mesh _brightnessExtractionMesh = new Mesh();

        readonly Matrix4x4 P = Matrix4x4.Ortho(0, 1, 0, 1, 0, 1);
        readonly Matrix4x4 V = Matrix4x4.identity;
        RenderTextureDescriptor _brightRTD;
        const int s_maxPasses = 3;
        const int nSamples = 8;

        readonly static Color COLOR_WHITE = new Color(0.63f, 0.63f, 0.63f, 0);
        readonly static Color[] COLOR_ChromaticAberration = new Color[8] {
            new Color(0.5f, 0.5f, 0.5f, 0),
            new Color(0.8f, 0.3f, 0.3f, 0),
            new Color(1.0f, 0.2f, 0.2f, 0),
            new Color(0.5f, 0.2f, 0.6f, 0),
            new Color(0.2f, 0.2f, 1.0f, 0),
            new Color(0.2f, 0.3f, 0.7f, 0),
            new Color(0.2f, 0.6f, 0.2f, 0),
            new Color(0.3f, 0.5f, 0.3f, 0),
        };
        static Color[,] s_aaColor = new Color[s_maxPasses, nSamples];

        readonly static int[] _StarTexs = new int[8] {
            Shader.PropertyToID("_StarTex0"),
            Shader.PropertyToID("_StarTex1"),
            Shader.PropertyToID("_StarTex2"),
            Shader.PropertyToID("_StarTex3"),
            Shader.PropertyToID("_StarTex4"),
            Shader.PropertyToID("_StarTex5"),
            Shader.PropertyToID("_StarTex6"),
            Shader.PropertyToID("_StarTex7"),
        };

        public CrossFilter_RenderPass(CrossFilter_RenderPassSettings settings, Material materialBloom, Material materialDualFilter)
        {
            _settings = settings;
            _materialBloom = materialBloom;
            _materialDualFilter = materialDualFilter;
            _brightnessExtractionMesh.MarkDynamic();


            for (int p = 0; p < s_maxPasses; p++)
            {
                float ratio = (float)(p + 1) / s_maxPasses;
                for (int s = 0; s < nSamples; s++)
                {
                    Color chromaticAberrColor = Color.Lerp(COLOR_ChromaticAberration[s], COLOR_WHITE, ratio);
                    s_aaColor[p, s] = Color.Lerp(COLOR_WHITE, chromaticAberrColor, 0.7f);
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
                new Vector3( x0, y0, 0),
                new Vector3( x0, y1, 0),
                new Vector3( x1, y1, 0),
                new Vector3( x1, y0, 0)
            });
            m.SetColors(new Color[4] { Color.white, Color.white, Color.white, Color.white });
            m.SetUVs(0, new Vector2[4] { Vector2.zero, Vector2.up, Vector2.one, Vector2.right });
            m.SetIndices(new int[4] { 0, 1, 2, 3 }, MeshTopology.Quads, 0);
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

            UpdateMesh(_brightnessExtractionMesh, scaledW, scaledH, 2, 2);

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

            cmd.SetProjectionMatrix(P);
            cmd.SetViewMatrix(V);
            
            // extract bright
            cmd.SetRenderTarget(_BrightTex);
            cmd.SetGlobalTexture(_MainTex, _ScaledTex);
            cmd.DrawMesh(_brightnessExtractionMesh, Matrix4x4.identity, _materialBloom, 0, 0);

            // blur bright
            cmd.SetGlobalTexture(_MainTex, _BrightTex);
            cmd.Blit(_BrightTex, _BaseStarBlurredTex1, _materialDualFilter, 0);
            cmd.SetGlobalTexture(_MainTex, _BaseStarBlurredTex1);
            cmd.Blit(_BaseStarBlurredTex1, _BaseStarBlurredTex2, _materialDualFilter, 1);

            // make a star
            RenderStar(cmd, _BaseStarBlurredTex2);

            // print
            cmd.SetGlobalTexture(_MainTex, _ScaledTex);
            cmd.SetGlobalTexture("_BloomBlurTex", _StarTexs[0]);
            cmd.Blit(_ScaledTex, _sourceRTI, _materialBloom, 1);

            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }

        void RenderStar(CommandBuffer cmd, int baseStarBlurredTex)
        {
            float srcW = _brightRTD.width;
            float srcH = _brightRTD.height;
            float m_fWorldRotY = Mathf.PI / 2;
            float radOffset = m_fWorldRotY / 5;

            int nStarLines = 6;// 광선의 줄기 개수
            
            for (int d = 0; d < nStarLines; d++)
            {
                int pTexSource = baseStarBlurredTex;
                float rad = radOffset + 2 * Mathf.PI * (float)d / nStarLines;
                float sin = Mathf.Sin(rad);
                float cos = Mathf.Cos(rad);
                Vector2 stepUV = new Vector2(0.1f * sin / srcW, 0.1f * cos / srcH);
                float attnPowScale = (Mathf.Atan(Mathf.PI / 4) + 0.1f) * (160.0f + 120.0f) / (srcW + srcH);

                int iWorkTexture = 0;
                for (int p = 0; p < s_maxPasses; p++)
                {
                    int pSurfDest;
                    if (p == s_maxPasses - 1)
                    {
                        pSurfDest = _StarTexs[d + 2];
                    }
                    else
                    {
                        pSurfDest = _StarTexs[iWorkTexture];
                    }

                    Vector4[] avSampleWeights = new Vector4[nSamples]; // xyzw
                    Vector4[] avSampleOffsets = new Vector4[nSamples]; // xy
                    for (int i = 0; i < nSamples; i++)
                    {
                        avSampleOffsets[i].x = stepUV.x * i;
                        avSampleOffsets[i].y = stepUV.y * i;

                        float lum = Mathf.Pow(0.95f, attnPowScale * i);
                        avSampleWeights[i] = s_aaColor[s_maxPasses - 1 - p, i] * lum * (p + 1.0f) * 0.5f;

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
                    cmd.SetGlobalTexture(_MainTex, pTexSource);
                    cmd.Blit(pTexSource, pSurfDest, _materialDualFilter, 2);

                    stepUV *= nSamples;
                    attnPowScale *= nSamples;
                    pTexSource = _StarTexs[iWorkTexture];
                    iWorkTexture ^= 1;
                }
            }

            // 합성.
            cmd.SetGlobalTexture("_S0Tex", _StarTexs[0 + 2]);
            cmd.SetGlobalTexture("_S1Tex", _StarTexs[1 + 2]);
            cmd.SetGlobalTexture("_S2Tex", _StarTexs[2 + 2]);
            cmd.SetGlobalTexture("_S3Tex", _StarTexs[3 + 2]);
            cmd.SetGlobalTexture("_S4Tex", _StarTexs[4 + 2]);
            cmd.SetGlobalTexture("_S5Tex", _StarTexs[5 + 2]);
            cmd.Blit(_StarTexs[1], _StarTexs[0], _materialDualFilter, 3);
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

    CrossFilter_RenderPass _pass;

    [SerializeField]
    CrossFilter_RenderPassSettings settings;

    public Material MaterialBloom;
    public Material MaterialDualFilter;

    public override void Create()
    {
        _pass = new CrossFilter_RenderPass(settings, MaterialBloom, MaterialDualFilter);
        _pass.renderPassEvent = RenderPassEvent.AfterRendering;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(_pass);
    }
}
