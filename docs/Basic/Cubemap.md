# Cubemap

- 텍스쳐를 받을 수 있는 Cubemap생성하기 : `Create > Legacy > Cubemap`

``` hlsl
TEXTURECUBE(_CubeMap);  SAMPLER(sampler_CubeMap);

half3 reflectVN = reflect(-V, N);
half4 cubeReflect = SAMPLE_TEXTURECUBE_LOD(_CubeMap, sampler_CubeMap, reflectVN, 0);

half3 refractVN = refract(-V, N, 1 / _RefractiveIndex);
half4 cubeRefract = SAMPLE_TEXTURECUBE_LOD(_CubeMap, sampler_CubeMap, refractVN, 0);
```

## CubemapGen

- <https://gpuopen.com/archived/cubemapgen/>
- <https://seblagarde.wordpress.com/2012/06/10/amd-cubemapgen-for-physically-based-rendering/>
- <https://github.com/gscept/CubeMapGen>

``` cs
// | AMD CubeMapGen | Unity |
// | -------------- | ----- |
// | X+             | -X    |
// | X-             | +X    |
// | Y+             | +Y    |
// | Y-             | -Y    |
// | Z+             | +Z    |
// | Z-             | -Z    |

using System.IO;
using UnityEditor;
using UnityEngine;

public class BakeStaticCubemap : ScriptableWizard
{
    static string imageDirectory = "Assets/CubemapImages";
    static string[] cubemapImage = new string[6] {
        "top+Y", "bottom-Y",
        "left-X", "right+X",
        "front+Z","back-Z",
    };
    static Vector3[] eulerAngles = new Vector3[6] {
        new Vector3(-90.0f, 0.0f, 0.0f), new Vector3(90.0f, 0.0f, 0.0f),
        new Vector3(0.0f, 90.0f, 0.0f), new Vector3(0.0f, -90.0f, 0.0f), 
        new Vector3(0.0f, 0.0f, 0.0f), new Vector3(0.0f, 180.0f, 0.0f),
    };


    public Transform renderPosition;
    public Cubemap cubemap;
    // Camera settings.
    public int cameraDepth = 24;
    public LayerMask cameraLayerMask = -1;
    public Color cameraBackgroundColor;
    public float cameraNearPlane = 0.1f;
    public float cameraFarPlane = 2500.0f;
    public bool cameraUseOcclusion = true;
    // Cubemap settings.
    public FilterMode cubemapFilterMode = FilterMode.Trilinear;
    // Quality settings.
    public int antiAliasing = 4;

    public bool IsCreateIndividualImages = false;

    [MenuItem("GameObject/Bake Cubemap")]
    static void RenderCubemap()
    {
        DisplayWizard("Bake CubeMap", typeof(BakeStaticCubemap), "Bake!");
    }

    void OnWizardUpdate()
    {
        helpString = "Set the position to render from and the cubemap to bake.";
        if (renderPosition != null && cubemap != null)
        {
            isValid = true;
        }
        else
        {
            isValid = false;
        }
    }

    void OnWizardCreate()
    {
        QualitySettings.antiAliasing = antiAliasing;
        cubemap.filterMode = cubemapFilterMode;

        GameObject go = new GameObject("CubemapCam", typeof(Camera));
        go.transform.position = renderPosition.position;
        go.transform.rotation = Quaternion.identity;

        Camera camera = go.GetComponent<Camera>();
        camera.depth = cameraDepth;
        camera.backgroundColor = cameraBackgroundColor;
        camera.cullingMask = cameraLayerMask;
        camera.nearClipPlane = cameraNearPlane;
        camera.farClipPlane = cameraFarPlane;
        camera.useOcclusionCulling = cameraUseOcclusion;

        camera.RenderToCubemap(cubemap);
        if (IsCreateIndividualImages)
        {
            if (!Directory.Exists(imageDirectory))
            {
                Directory.CreateDirectory(imageDirectory);
            }
            RenderIndividualCubemapImages(camera);
        }
        DestroyImmediate(go);
    }

    void RenderIndividualCubemapImages(Camera camera)
    {
        camera.backgroundColor = Color.black;
        camera.clearFlags = CameraClearFlags.Skybox;
        camera.fieldOfView = 90;
        camera.aspect = 1.0f;
        camera.transform.rotation = Quaternion.identity;

        for (int camOrientation = 0; camOrientation < eulerAngles.Length; camOrientation++)
        {
            string imageName = Path.Combine(imageDirectory, cubemap.name + "_" + cubemapImage[camOrientation] + ".png");
            camera.transform.eulerAngles = eulerAngles[camOrientation];
            RenderTexture renderTex = new RenderTexture(cubemap.height, cubemap.height, cameraDepth);
            camera.targetTexture = renderTex;
            camera.Render();
            RenderTexture.active = renderTex;
            Texture2D img = new Texture2D(cubemap.height, cubemap.height, TextureFormat.RGB24, false);
            img.ReadPixels(new Rect(0, 0, cubemap.height, cubemap.height), 0, 0);
            RenderTexture.active = null;
            DestroyImmediate(renderTex);
            byte[] imgBytes = img.EncodeToPNG();
            File.WriteAllBytes(imageName, imgBytes);
            AssetDatabase.ImportAsset(imageName, ImportAssetOptions.ForceUpdate);
        }
        AssetDatabase.Refresh();
    }
}
```

## Ref

- <https://developer.arm.com/documentation/102179/0100/Implement-reflections-with-a-local-cubemap>
- [NDC2011 - PRT(Precomputed Radiance Transfer) 및 SH(Spherical Harmonics) 개괄](https://www.slideshare.net/honestee/choi-jihyun-ndc2011)
