using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class Uber_RenderPassFeature : ScriptableRendererFeature
{

    [Serializable]
    public class Uber_RenderPassSettings
    {
        public bool _UBER_A;
        public bool _UBER_B;
    }

    class Uber_RenderPass : ScriptableRenderPass
    {
        Uber_RenderPassSettings _settings;
        readonly static int _TempRT = Shader.PropertyToID("_TempRT");
        const int PASS_SobelFilter = 0;

        RenderTargetIdentifier _colorBuffer;
        Material _mat_uber;
        public Uber_RenderPass(Uber_RenderPassSettings settings)
        {
            _settings = settings;
            if (_mat_uber == null)
            {
                _mat_uber = CoreUtils.CreateEngineMaterial("Hidden/Uber");
            }

            if (settings._UBER_A)
            {
                _mat_uber.EnableKeyword("_UBER_A");
            }
            else
            {
                _mat_uber.DisableKeyword("_UBER_A");
            }

            if (settings._UBER_B)
            {
                _mat_uber.EnableKeyword("_UBER_B");
            }
            else
            {
                _mat_uber.DisableKeyword("_UBER_B");
            }
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            _colorBuffer = renderingData.cameraData.renderer.cameraColorTarget;
            cmd.GetTemporaryRT(_TempRT, renderingData.cameraData.cameraTargetDescriptor);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get(nameof(Uber_RenderPass));
            Blit(cmd, _colorBuffer, _TempRT, _mat_uber, PASS_SobelFilter);
            Blit(cmd, _TempRT, _colorBuffer);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(_TempRT);
        }
    }

    [SerializeField]
    Uber_RenderPassSettings _settings = null;
    Uber_RenderPass _pass;

    public override void Create()
    {
        _pass = new Uber_RenderPass(_settings);
        _pass.renderPassEvent = RenderPassEvent.AfterRendering;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(_pass);
    }
}


