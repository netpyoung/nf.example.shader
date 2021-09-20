using System.IO;
using UnityEditor;
using UnityEngine;

public class BakeStaticCubemap : ScriptableWizard
{
    static string imageDirectory = "Assets/CubemapImages";
    static string[] cubemapImage = new string[] {
        "front+Z", "right+X",
        "back-Z", "left-X",
        "top+Y", "bottom-Y"
    };
    static Vector3[] eulerAngles = new Vector3[] {
        new Vector3(0.0f, 0.0f, 0.0f), new Vector3(0.0f, -90.0f, 0.0f),
        new Vector3(0.0f, 180.0f, 0.0f), new Vector3(0.0f, 90.0f, 0.0f),
        new Vector3(-90.0f, 0.0f, 0.0f), new Vector3(90.0f, 0.0f, 0.0f)
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