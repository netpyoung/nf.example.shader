using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering.Universal;

public class Brightness_RenderPassFeature : ScriptableRendererFeature
{

    [Serializable]
    public struct Brightness_RenderPassSettings
    {
        public float _AdaptionConstant;
        public float _Key;
    }

    class Brightness_RenderPass : ScriptableRenderPass
    {
        Brightness_RenderPassSettings _settings;
        readonly static int _TmpCurrMipmapRT = Shader.PropertyToID("_TmpCurrMipmapTex");
        readonly static int _TmpCopyRT = Shader.PropertyToID("_TmpCopyTex");
        readonly static int _LumaCurrTex = Shader.PropertyToID("_LumaCurrTex");
        readonly static int _LumaAdaptPrevTex = Shader.PropertyToID("_LumaAdaptPrevTex");
        readonly static int _LumaAdaptCurrTex = Shader.PropertyToID("_LumaAdaptCurrTex");

        const int PASS_Brightness_CalcuateLuma = 0;
        const int PASS_Brightness_CopyLuma = 1;
        const int PASS_Brightness_AdaptedFilter = 2;
        const int PASS_EyeAdaptation_ToneMapping = 0;

        RenderTargetIdentifier _source;
        Material _mat_Brightness;
        Material _mat_EyeAdaptation;
        RenderTexture _LumaPrevRT;
        RenderTexture _LumaCurrRT;
        RenderTexture _LumaAdaptCurrRT;
        RenderTextureDescriptor _TmpCurrMipmapRTD;

        public Brightness_RenderPass(Brightness_RenderPassSettings settings)
        {
            _settings = settings;
            if (_mat_Brightness == null)
            {

                _mat_Brightness = CoreUtils.CreateEngineMaterial("Hidden/Brightness");
            }
            if (_mat_EyeAdaptation == null)
            {
                _mat_EyeAdaptation = CoreUtils.CreateEngineMaterial("Hidden/EyeAdaptation");
            }

            _mat_Brightness.SetFloat("_AdaptionConstant", settings._AdaptionConstant);
            _mat_EyeAdaptation.SetFloat("_Key", settings._Key);

            _LumaPrevRT = new RenderTexture(1, 1, 0, GraphicsFormat.R16G16_SFloat, 0)
            {
                useMipMap = false,
                autoGenerateMips = false,
            };
            _LumaCurrRT = new RenderTexture(1, 1, 0, GraphicsFormat.R16G16_SFloat, 0)
            {
                useMipMap = false,
                autoGenerateMips = false,
            };
            _LumaAdaptCurrRT = new RenderTexture(1, 1, 0, GraphicsFormat.R16G16_SFloat, 0)
            {
                useMipMap = false,
                autoGenerateMips = false,
            };
            _LumaPrevRT.Create();
            _LumaCurrRT.Create();
            _LumaAdaptCurrRT.Create();
        }

        ~Brightness_RenderPass()
        {
            _LumaPrevRT.Release();
            _LumaCurrRT.Release();
            _LumaAdaptCurrRT.Release();
        }

        public static int ToPow2RoundUp(int x)
        {
            if (x == 0)
            {
                return 0;
            }
            return MakeMSB(x - 1) + 1;
        }

        public static int MakeMSB(int x)
        {
            x |= x >> 1;
            x |= x >> 2;
            x |= x >> 4;
            x |= x >> 8;
            x |= x >> 16;
            return x;
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            _source = renderingData.cameraData.renderer.cameraColorTarget;

            int w = renderingData.cameraData.camera.pixelWidth;
            int h = renderingData.cameraData.camera.pixelHeight;
            w = ToPow2RoundUp(w / 2);
            h = ToPow2RoundUp(h / 2);
            _TmpCurrMipmapRTD = new RenderTextureDescriptor(w, h, GraphicsFormat.R16G16_SFloat, 0)
            {
                autoGenerateMips = true,
                useMipMap = true
            };
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.isSceneViewCamera)
            {
                return;
            }
            
            CommandBuffer cmd = CommandBufferPool.Get(nameof(Brightness_RenderPass));
            cmd.SetGlobalTexture(_LumaAdaptPrevTex, _LumaPrevRT);
            cmd.SetGlobalTexture(_LumaCurrTex, _LumaCurrRT);
            cmd.SetGlobalTexture(_LumaAdaptCurrTex, _LumaAdaptCurrRT);

            cmd.GetTemporaryRT(_TmpCopyRT, renderingData.cameraData.cameraTargetDescriptor, FilterMode.Bilinear);
            Blit(cmd, _source, _TmpCopyRT);

            cmd.GetTemporaryRT(_TmpCurrMipmapRT, _TmpCurrMipmapRTD, FilterMode.Bilinear);
            cmd.SetGlobalTexture("_TmpCurrMipmapTex", _TmpCurrMipmapRT);

            Blit(cmd, _source, _TmpCurrMipmapRT, _mat_Brightness, PASS_Brightness_CalcuateLuma);
            Blit(cmd, _TmpCurrMipmapRT, _LumaCurrRT, _mat_Brightness, PASS_Brightness_CopyLuma);
            cmd.ReleaseTemporaryRT(_TmpCurrMipmapRT);

            Blit(cmd, _LumaCurrRT, _LumaAdaptCurrRT, _mat_Brightness, PASS_Brightness_AdaptedFilter);
            Blit(cmd, _TmpCopyRT, _source, _mat_EyeAdaptation, PASS_EyeAdaptation_ToneMapping);
            cmd.ReleaseTemporaryRT(_TmpCopyRT);

            Blit(cmd, _LumaAdaptCurrRT, _LumaPrevRT);
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
        }
    }

    [SerializeField]
    Brightness_RenderPassSettings _settings = new Brightness_RenderPassSettings();
    Brightness_RenderPass _pass;

    public override void Create()
    {
        _pass = new Brightness_RenderPass(_settings);
        _pass.renderPassEvent = RenderPassEvent.AfterRendering;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(_pass);
    }
}


