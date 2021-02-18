using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class GammaUIFix : ScriptableRendererFeature
{
    public Material material;

    public GammaUIFix()
    {
    }

    public override void Create()
    {
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        RenderTargetIdentifier cameraColorTarget = renderer.cameraColorTarget;

        DrawUIIntoRTPass DrawUIIntoRTPass = new DrawUIIntoRTPass(RenderPassEvent.BeforeRenderingTransparents, cameraColorTarget);
        BlitPass BlitRenderPassesToScreen = new BlitPass(RenderPassEvent.AfterRenderingTransparents, cameraColorTarget, material);

        renderer.EnqueuePass(DrawUIIntoRTPass);
        renderer.EnqueuePass(BlitRenderPassesToScreen);
    }

    //-------------------------------------------------------------------------

    class DrawUIIntoRTPass : ScriptableRenderPass
    {
        public static int UITemporaryRT = Shader.PropertyToID("UITemporaryRT");
        public static RenderTargetIdentifier UIRenderTargetID = new RenderTargetIdentifier(UITemporaryRT);

        public DrawUIIntoRTPass(RenderPassEvent renderPassEvent, RenderTargetIdentifier colorHandle)
        {
            this.renderPassEvent = renderPassEvent;
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            RenderTextureDescriptor descriptor = cameraTextureDescriptor;
            descriptor.colorFormat = RenderTextureFormat.Default;
            cmd.GetTemporaryRT(UITemporaryRT, descriptor);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get("Draw UI Into RT Pass");

            cmd.SetRenderTarget(UIRenderTargetID);
            cmd.ClearRenderTarget(clearDepth: true, clearColor: true, Color.clear);

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        public override void FrameCleanup(CommandBuffer cmd)
        {
            if (cmd == null)
            {
                throw new ArgumentNullException("cmd");
            }
            base.FrameCleanup(cmd);
        }
    }

    //-------------------------------------------------------------------------

    class BlitPass : ScriptableRenderPass
    {
        RenderTargetIdentifier _colorHandle;
        Material _material;

        public BlitPass(RenderPassEvent renderPassEvent, RenderTargetIdentifier colorHandle, Material mat)
        {
            this.renderPassEvent = renderPassEvent;
            this._colorHandle = colorHandle;
            this._material = mat;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get("Blit Pass");

            cmd.Blit(DrawUIIntoRTPass.UIRenderTargetID, _colorHandle, _material);

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        public override void FrameCleanup(CommandBuffer cmd)
        {
            if (cmd == null)
            {
                throw new ArgumentNullException("cmd");
            }

            cmd.ReleaseTemporaryRT(DrawUIIntoRTPass.UITemporaryRT);

            base.FrameCleanup(cmd);
        }
    }

    //-------------------------------------------------------------------------
}