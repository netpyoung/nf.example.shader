using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;

public class LightShaft_RenderPassFeature : ScriptableRendererFeature
{
    [SerializeField]
    private LightShaft_RenderPassSettings _settings = null;
    private LightShaft_RenderPass _pass;

    public override void Create()
    {
        _pass = new LightShaft_RenderPass(_settings);
        _pass.renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(_pass);
    }


    // ========================================================================================================================================
    [Serializable]
    public class LightShaft_RenderPassSettings
    {
        [Range(0, 64)] public int _MaxIteration = 64;
        [Range(0f, 20f)] public float _MinDistance = 0.4f;
        [Range(0f, 20f)] public float _MaxDistance = 12;
        [Range(0f, 2f)] public float _Intensity = 1;
        public float _DepthOutsideDecreaseValue = 1;
        public float _DepthOutsideDecreaseSpeed = 1;
        public E_DEBUG DebugMode;
    }

    public enum E_DEBUG
    {
        NONE,
        SHAFT_ONLY,
        SHAFT_FINAL,
    }


    // ========================================================================================================================================
    private class PassData
    {
        public TextureHandle Tex_ActivateColor;
        public TextureHandle Tex_TmpCopy;
        public TextureHandle Tex_LightShaftMask;
        public Material Mat_LightShaft;
        public LightShaft_RenderPassSettings Settings;
    }


    // ========================================================================================================================================
    private class LightShaft_RenderPass : ScriptableRenderPass
    {
        private LightShaft_RenderPassSettings _settings;

        private readonly static int _LightShaftMaskTex = Shader.PropertyToID("_LightShaftMaskTex");

        private const int PASS_LIGHTSHAFT_GRADIENTFOG = 0;
        private const int PASS_LIGHTSHAFT_COMBINE = 1;

        private Material _materia_LightShaft;

        public LightShaft_RenderPass(LightShaft_RenderPassSettings settings)
        {
            _settings = settings;
            if (_materia_LightShaft == null)
            {
                _materia_LightShaft = CoreUtils.CreateEngineMaterial("srp/LightShaft");
            }
            _materia_LightShaft.SetFloat("_MaxIteration", settings._MaxIteration);
            _materia_LightShaft.SetFloat("_MinDistance", settings._MinDistance);
            _materia_LightShaft.SetFloat("_MaxDistance", settings._MaxDistance);
            _materia_LightShaft.SetFloat("_Intensity", settings._Intensity);
            _materia_LightShaft.SetFloat("_DepthOutsideDecreaseValue", settings._DepthOutsideDecreaseValue);
            _materia_LightShaft.SetFloat("_DepthOutsideDecreaseSpeed", settings._DepthOutsideDecreaseSpeed);
        }

        public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
        {
            string passName = "Unsafe Pass";

            UniversalResourceData resourceData = frameData.Get<UniversalResourceData>();

            using (IUnsafeRenderGraphBuilder builder = renderGraph.AddUnsafePass(passName, out PassData passData))
            {
                SetupPassData(renderGraph, frameData, passData);

                builder.UseTexture(passData.Tex_ActivateColor, AccessFlags.ReadWrite);
                builder.UseTexture(passData.Tex_TmpCopy, AccessFlags.ReadWrite);
                builder.UseTexture(passData.Tex_LightShaftMask, AccessFlags.ReadWrite);
                builder.AllowPassCulling(value: false);
                builder.SetRenderFunc<PassData>(ExecutePass);
            }
        }

        private void SetupPassData(RenderGraph renderGraph, ContextContainer frameData, PassData passData)
        {
            UniversalCameraData cameraData = frameData.Get<UniversalCameraData>();
            UniversalResourceData resourceData = frameData.Get<UniversalResourceData>();

            passData.Tex_ActivateColor = resourceData.activeColorTexture;

            TextureDesc td1 = renderGraph.GetTextureDesc(resourceData.activeColorTexture);
            passData.Tex_TmpCopy = renderGraph.CreateTexture(td1);

            TextureDesc td2 = td1;
            td2.width /= 4;
            td2.height /= 4;
            passData.Tex_LightShaftMask = renderGraph.CreateTexture(td2);

            Camera camera = cameraData.camera;
            _materia_LightShaft.SetVector("_CameraPositionWS", camera.transform.position);
            _materia_LightShaft.SetMatrix("_Matrix_CameraFrustum", FrustumCorners(camera));
            passData.Mat_LightShaft = _materia_LightShaft;
            passData.Settings = _settings;
        }

        private static void ExecutePass(PassData data, UnsafeGraphContext context)
        {
            if (data.Settings.DebugMode == E_DEBUG.NONE)
            {
                return;
            }

            UnsafeCommandBuffer cmd = context.cmd;
            CommandBuffer nativeCmd = CommandBufferHelpers.GetNativeCommandBuffer(cmd);

            Blitter.BlitCameraTexture(nativeCmd, data.Tex_ActivateColor, data.Tex_TmpCopy);

            nativeCmd.Blit(null, data.Tex_LightShaftMask, data.Mat_LightShaft, PASS_LIGHTSHAFT_GRADIENTFOG);
            if (data.Settings.DebugMode == E_DEBUG.SHAFT_ONLY)
            {
                Blitter.BlitCameraTexture(nativeCmd, data.Tex_LightShaftMask, data.Tex_ActivateColor);
            }
            else
            {
                nativeCmd.SetGlobalTexture(_LightShaftMaskTex, data.Tex_LightShaftMask);
                nativeCmd.Blit(data.Tex_TmpCopy, data.Tex_ActivateColor, data.Mat_LightShaft, PASS_LIGHTSHAFT_COMBINE);
            }
        }

        private Matrix4x4 FrustumCorners(Camera cam)
        {
            // ref: http://hventura.com/unity-post-process-v2-raymarching.html

            Transform camtr = cam.transform;

            Vector3[] frustumCorners = new Vector3[4];

            cam.CalculateFrustumCorners(
                new Rect(0, 0, 1, 1),  // viewport
                cam.farClipPlane,      // z
                cam.stereoActiveEye,   // eye
                frustumCorners         // outCorners
            );

            // frustumCorners
            //    1  +----+ 2
            //       |    |
            //    0  +----+ 3

            Matrix4x4 frustumVectorsArray = Matrix4x4.identity;
            // frustumVectorsArray
            //    2  +----+ 3
            //       |    |
            //    0  +----+ 1
            frustumVectorsArray.SetRow(0, camtr.TransformVector(frustumCorners[0]));
            frustumVectorsArray.SetRow(1, camtr.TransformVector(frustumCorners[3]));
            frustumVectorsArray.SetRow(2, camtr.TransformVector(frustumCorners[1]));
            frustumVectorsArray.SetRow(3, camtr.TransformVector(frustumCorners[2]));

            // in Shader
            // IN.uv
            // (0,1) +----+ (1,1)
            //       |    |
            // (0,0) +----+ (1,0)
            //
            // int frustumIndex = (int)(IN.uv.x +  2 * IN.uv.y);
            //    2  +----+ 3
            //       |    |
            //    0  +----+ 1
            return frustumVectorsArray;
        }
    }
}