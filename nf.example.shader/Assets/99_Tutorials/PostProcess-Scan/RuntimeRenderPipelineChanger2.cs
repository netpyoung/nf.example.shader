using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class RuntimeRenderPipelineChanger2 : MonoBehaviour
{
    public RenderPipelineAsset renderPipelineAsset;

    void Awake()
    {
        GraphicsSettings.renderPipelineAsset = renderPipelineAsset;
    }
}
