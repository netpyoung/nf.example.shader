using UnityEngine;
using UnityEngine.Rendering;

public class RuntimeRenderPipelineChanger2 : MonoBehaviour
{
    public RenderPipelineAsset renderPipelineAsset;

    void Awake()
    {
        GraphicsSettings.defaultRenderPipeline = renderPipelineAsset;
    }
}
