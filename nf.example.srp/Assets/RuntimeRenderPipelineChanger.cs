using UnityEngine;
using UnityEngine.Rendering;

public class RuntimeRenderPipelineChanger : MonoBehaviour
{
    public RenderPipelineAsset renderPipelineAsset;

    void Awake()
    {
        GraphicsSettings.renderPipelineAsset = renderPipelineAsset;
    }
}
