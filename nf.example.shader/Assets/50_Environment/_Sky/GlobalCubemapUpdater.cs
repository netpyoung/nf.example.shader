using UnityEngine;
using UnityEngine.Experimental.Rendering;

public class GlobalCubemapUpdater : MonoBehaviour
{
    public Cubemap _cubemap;
    public Camera _camera;

    void Start()
    {
        if (_cubemap == null)
        {
            _cubemap = new Cubemap(128, GraphicsFormat.R32G32B32A32_SFloat, TextureCreationFlags.MipChain, 3);
        }

        RenderSettings.customReflectionTexture = _cubemap;
        _camera.RenderToCubemap(_cubemap);
    }
}
