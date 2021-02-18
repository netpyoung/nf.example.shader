using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class RuntimeRenderPipelineChanger : MonoBehaviour
{
    public Camera UICamera;
    public RenderPipelineAsset renderPipelineAsset;

    void Awake()
    {
        GraphicsSettings.renderPipelineAsset = renderPipelineAsset;
        UICamera.GetComponent<UniversalAdditionalCameraData>().SetRenderer(1);
    }
}
