using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class LightShaft_RenderPassFeature : ScriptableRendererFeature
{
    public enum E_DEBUG
    {
        NONE,
        SHAFT_ONLY,
        SHAFT_FINAL,
    }

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

    class LightShaft_RenderPass : ScriptableRenderPass
    {
        LightShaft_RenderPassSettings _settings;

        readonly static int _LightShaftMaskTex = Shader.PropertyToID("_LightShaftMaskTex");
        readonly static int _TmpCopyRT = Shader.PropertyToID("_TmpCopyTex");

        const int PASS_LIGHTSHAFT_GRADIENTFOG = 0;
        const int PASS_LIGHTSHAFT_COMBINE = 1;
        
        const int PASS_DUALFILTER_DOWN = 0;
        const int PASS_DUALFILTER_UP = 1;

        RenderTargetIdentifier _colorBuffer;
        Material _materia_LightShaft;
        Material _materia_DualFilter;
        public LightShaft_RenderPass(LightShaft_RenderPassSettings settings)
        {
            _settings = settings;
            if (_materia_LightShaft == null)
            {
                _materia_LightShaft = CoreUtils.CreateEngineMaterial("Hidden/LightShaft");
            }
            if (_materia_DualFilter == null)
            {
                _materia_DualFilter = CoreUtils.CreateEngineMaterial("srp/DualFilter");
            }
            
            _materia_LightShaft.SetFloat("_MaxIteration", settings._MaxIteration);
            _materia_LightShaft.SetFloat("_MinDistance", settings._MinDistance);
            _materia_LightShaft.SetFloat("_MaxDistance", settings._MaxDistance);
            _materia_LightShaft.SetFloat("_Intensity", settings._Intensity);
            _materia_LightShaft.SetFloat("_DepthOutsideDecreaseValue", settings._DepthOutsideDecreaseValue);
            _materia_LightShaft.SetFloat("_DepthOutsideDecreaseSpeed", settings._DepthOutsideDecreaseSpeed);
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            ref CameraData cameraData = ref renderingData.cameraData;
            Camera camera = cameraData.camera;
            int w = cameraData.camera.scaledPixelWidth / 4;
            int h = cameraData.camera.scaledPixelHeight / 4;

            _colorBuffer = cameraData.renderer.cameraColorTarget;
            _materia_LightShaft.SetVector("_CameraPositionWS", camera.transform.position);
            _materia_LightShaft.SetMatrix("_Matrix_CameraFrustum", FrustumCorners(camera));

            cmd.GetTemporaryRT(_LightShaftMaskTex, w, h, 0, FilterMode.Bilinear);
            cmd.GetTemporaryRT(_TmpCopyRT, cameraData.cameraTargetDescriptor, FilterMode.Bilinear);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.isSceneViewCamera)
            {
                return;
            }

            if (_settings.DebugMode == E_DEBUG.NONE)
            {
                return;
            }

            CommandBuffer cmd = CommandBufferPool.Get(nameof(LightShaft_RenderPass));
            cmd.Blit(_colorBuffer, _TmpCopyRT);

            cmd.Blit(null, _LightShaftMaskTex, _materia_LightShaft, PASS_LIGHTSHAFT_GRADIENTFOG);
            if (_settings.DebugMode == E_DEBUG.SHAFT_ONLY)
            {
                cmd.Blit(_LightShaftMaskTex, _colorBuffer);
            }
            else
            {
                cmd.Blit(_TmpCopyRT, _colorBuffer, _materia_LightShaft, PASS_LIGHTSHAFT_COMBINE);
            }
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(_LightShaftMaskTex);
            cmd.ReleaseTemporaryRT(_TmpCopyRT);
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

    [SerializeField]
    LightShaft_RenderPassSettings _settings = null;
    LightShaft_RenderPass _pass;

    public override void Create()
    {
        _pass = new LightShaft_RenderPass(_settings);
        _pass.renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(_pass);
    }
}