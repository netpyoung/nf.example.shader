using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class RuntimeRenderPipelineChanger : MonoBehaviour
{
    public Camera MainCamera;
    public Camera UICamera;
    public RenderPipelineAsset renderPipelineAsset;

    void Awake()
    {
        GraphicsSettings.renderPipelineAsset = renderPipelineAsset;
        UICamera.GetComponent<UniversalAdditionalCameraData>().SetRenderer(1);
        MainCamera.GetComponent<UniversalAdditionalCameraData>().SetRenderer(0);
    }
}
