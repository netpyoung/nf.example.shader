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
        readonly static int _TmpCurrMipmapTex = Shader.PropertyToID("_TmpCurrMipmapTex");
        readonly static int _TmpCopyTex = Shader.PropertyToID("_TmpCopyTex");
        readonly static int _LumaCurrTex = Shader.PropertyToID("_LumaCurrTex");
        readonly static int _LumaPrevTex = Shader.PropertyToID("_LumaPrevTex");
        readonly static int _LumaAdaptTex = Shader.PropertyToID("_LumaAdaptTex");

        const int PASS_SobelFilter = 0;
        const int PASS_AdaptedFilter = 1;
        RenderTargetIdentifier _source;
        private RenderTargetIdentifier _destination;
        Material _bright_material;
        Material _eye_material;
        RenderTexture _LumaPrevRT;
        RenderTexture _LumaCurrRT;
        RenderTexture _LumaAdaptRT;
        RenderTextureDescriptor _brightCurrRTD;

        public Brightness_RenderPass(Brightness_RenderPassSettings settings)
        {
            _settings = settings;
            if (_bright_material == null)
            {

                _bright_material = CoreUtils.CreateEngineMaterial("Hidden/Brightness");
            }
            if (_eye_material == null)
            {
                _eye_material = CoreUtils.CreateEngineMaterial("Hidden/EyeAdaptation");
            }

            _bright_material.SetFloat("_AdaptionConstant", settings._AdaptionConstant);
            _eye_material.SetFloat("_Key", settings._Key);
            
            _LumaPrevRT = new RenderTexture(1, 1, 0, GraphicsFormat.R16G16_SFloat, 0);
            _LumaCurrRT = new RenderTexture(1, 1, 0, GraphicsFormat.R16G16_SFloat, 0);
            _LumaAdaptRT = new RenderTexture(1, 1, 0, GraphicsFormat.R16G16_SFloat, 0);
            _LumaPrevRT.Create();
            _LumaCurrRT.Create();
            _LumaAdaptRT.Create();
        }

        ~Brightness_RenderPass()
        {
            _LumaPrevRT.Release();
            _LumaCurrRT.Release();
            _LumaAdaptRT.Release();
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
            _destination = RenderTargetHandle.CameraTarget.Identifier();

            int w = renderingData.cameraData.camera.pixelWidth;
            int h = renderingData.cameraData.camera.pixelHeight;
            w = ToPow2RoundUp(w / 2);
            h = ToPow2RoundUp(h / 2);
            _brightCurrRTD = new RenderTextureDescriptor(w, h, GraphicsFormat.R16G16B16A16_SFloat, 0);
            // _brightCurrRTD = new RenderTextureDescriptor(w, h, GraphicsFormat.R32G32B32A32_SFloat, 0);
            _brightCurrRTD.autoGenerateMips = true;
            _brightCurrRTD.useMipMap = true;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.isSceneViewCamera)
            {
                return;
            }
            
            CommandBuffer cmd = CommandBufferPool.Get(nameof(Brightness_RenderPass));
            cmd.SetGlobalTexture(_LumaPrevTex, _LumaPrevRT);
            cmd.SetGlobalTexture(_LumaCurrTex, _LumaCurrRT);
            cmd.SetGlobalTexture(_LumaAdaptTex, _LumaAdaptRT);

            cmd.GetTemporaryRT(_TmpCopyTex, renderingData.cameraData.cameraTargetDescriptor);
            cmd.CopyTexture(_source, _TmpCopyTex);

            cmd.GetTemporaryRT(_TmpCurrMipmapTex, _brightCurrRTD);
            Blit(cmd, _source, _TmpCurrMipmapTex);
            Blit(cmd, _TmpCurrMipmapTex, _LumaCurrRT, _bright_material, PASS_SobelFilter);
            cmd.ReleaseTemporaryRT(_TmpCurrMipmapTex);

            Blit(cmd, _LumaCurrRT, _LumaAdaptRT, _bright_material, PASS_AdaptedFilter);
            Blit(cmd, _TmpCopyTex, _source, _eye_material, 0);
            cmd.ReleaseTemporaryRT(_TmpCopyTex);

            Blit(cmd, _LumaAdaptRT, _LumaPrevRT);
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
        }
    }

    [SerializeField]
    Brightness_RenderPassSettings _settings;
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


