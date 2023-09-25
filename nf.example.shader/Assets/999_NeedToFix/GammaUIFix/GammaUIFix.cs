using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;


public class GammaUIFix : ScriptableRendererFeature
{
    private DrawUIIntoRTPass _drawUIIntoRTPass;
    private BlitPass _blitRenderPassesToScreen;
    public Material Material;
    public static RTCollection rTCollection = new RTCollection();

    protected override void Dispose(bool disposing)
    {
        rTCollection.Dispose();
    }

    public override void Create()
    {
        _drawUIIntoRTPass = new DrawUIIntoRTPass(RenderPassEvent.AfterRendering);
        _blitRenderPassesToScreen = new BlitPass(RenderPassEvent.AfterRendering, Material);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        CameraData cameraData = renderingData.cameraData;
        if (cameraData.cameraType == CameraType.Game)
        {
            rTCollection.Setup(cameraData.cameraTargetDescriptor);

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
    }

    public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
    {
        CameraData cameraData = renderingData.cameraData;
        if (cameraData.cameraType == CameraType.Game)
        {
            string cameraName = cameraData.camera.name;
            if (cameraName == "UI Camera")
            {
                _drawUIIntoRTPass.ConfigureInput(ScriptableRenderPassInput.Color);
                _drawUIIntoRTPass.Setup(renderer.cameraColorTargetHandle);
            }
            else if (cameraName == "Main Camera")
            {
                _blitRenderPassesToScreen.ConfigureInput(ScriptableRenderPassInput.Color);
                _blitRenderPassesToScreen.Setup(renderer.cameraColorTargetHandle);
            }
        }
    }

    // =========================================================================================================
    // =========================================================================================================
    public class RTCollection : IDisposable
    {
        public static int UITemporaryRT_Id = Shader.PropertyToID("_UITemporaryRT");

        public RTHandle UITemporaryRT => _UITemporaryRT;
        private RTHandle _UITemporaryRT;

        internal void Setup(RenderTextureDescriptor mainDesc)
        {
            if (_UITemporaryRT != null)
            {
                return;
            }

            RenderTextureFormat tf = RenderTextureFormat.ARGB32;
            RenderTextureDescriptor rtdesc = new RenderTextureDescriptor(mainDesc.width, mainDesc.height, tf, 0);
            RenderingUtils.ReAllocateIfNeeded(ref _UITemporaryRT, rtdesc, FilterMode.Bilinear, TextureWrapMode.Clamp, name: "_UITemporaryRT");
        }

        public void Dispose()
        {
            if (_UITemporaryRT == null)
            {
                return;
            }

            RTHandles.Release(_UITemporaryRT);
            _UITemporaryRT = null;
        }
    }

    // =========================================================================================================
    // =========================================================================================================
    class DrawUIIntoRTPass : ScriptableRenderPass
    {
        const string RENDER_TAG = nameof(DrawUIIntoRTPass);
        private RTHandle _cameraColorTargetHandle;

        public DrawUIIntoRTPass(RenderPassEvent renderPassEvent)
        {
            this.renderPassEvent = renderPassEvent;
        }

        internal void Setup(RTHandle cameraColorTargetHandle)
        {
            _cameraColorTargetHandle = cameraColorTargetHandle;
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            ConfigureTarget(_cameraColorTargetHandle);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CameraData cameraData = renderingData.cameraData;
            if (cameraData.camera.cameraType != CameraType.Game)
            {
                return;
            }

            CommandBuffer cmd = CommandBufferPool.Get(RENDER_TAG);

            // cmd.SetRenderTarget(GammaUIFix.rTCollection.UITemporaryRT);
//            cmd.ClearRenderTarget(clearDepth: true, clearColor: true, Color.clear);
            Blitter.BlitCameraTexture(cmd, _cameraColorTargetHandle, GammaUIFix.rTCollection.UITemporaryRT);

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }

    // =========================================================================================================
    // =========================================================================================================
    class BlitPass : ScriptableRenderPass
    {
        const string RENDER_TAG = nameof(BlitPass);

        private RTHandle _cameraColorTargetHandle;
        private Material _material;

        public BlitPass(RenderPassEvent renderPassEvent, Material mat)
        {
            this.renderPassEvent = renderPassEvent;
            _material = mat;
        }

        internal void Setup(RTHandle cameraColorTargetHandle)
        {
            _cameraColorTargetHandle = cameraColorTargetHandle;
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            ConfigureTarget(_cameraColorTargetHandle);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CameraData cameraData = renderingData.cameraData;
            if (cameraData.camera.cameraType != CameraType.Game)
            {
                return;
            }

            if (_material == null)
            {
                return;
            }
            return;
            CommandBuffer cmd = CommandBufferPool.Get(RENDER_TAG);

            // cmd.Blit(DrawUIIntoRTPass.UIRenderTargetID, _cameraColorTargetHandle, _material);
            // Blitter.BlitCameraTexture(cmd, GammaUIFix.rTCollection.UITemporaryRT, _cameraColorTargetHandle, _material, 0);

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }
}