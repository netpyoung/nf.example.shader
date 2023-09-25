using UnityEngine;

[ExecuteInEditMode]
public class BRDFLightReceiver : MonoBehaviour
{
    public float intensity = 1.0f;

    public float diffuseIntensity = 1.0f;
    public Color keyColor = new Color(188.0f / 255, 158.0f / 255, 118.0f / 255, 0.0f);
    public Color fillColor = new Color(86.0f / 255, 91.0f / 255, 108.0f / 255, 0.0f);
    public Color backColor = new Color(44.0f / 255, 54.0f / 255, 57.0f / 255, 0.0f);
    public float wrapAround = 0.0f;
    public float metalic = 0.0f;

    public float specularIntensity = 1.0f;
    public float specularShininess = 0.078125f;

    public float fresnelIntensity = 0.0f; // water, rim
    public float fresnelSharpness = 0.5f;
    public Color fresnelReflectionColor = new Color(86.0f / 255, 91.0f / 255, 108.0f / 255, 0.0f);

    public float translucency = 0.0f; // skin
    public Color translucentColor = new Color(255.0f / 255, 82.0f / 255, 82.0f / 255, 0.0f);

    public int lookupTextureWidth = 128;
    public int lookupTextureHeight = 128;

    public Texture2D lookupTexture;
    
    public int offsetRenderQueue = 0;
    public bool affectChildren = true;

    private Texture2D _internallyCreatedTexture;
    private Renderer[] _renderers;
    private Shader _shader;


    // Start is called before the first frame update
    void Start()
    {
        if (lookupTexture != null)
        {
            lookupTexture.wrapMode = TextureWrapMode.Clamp;
        }

        if (Application.isEditor)
        {
            _shader = Shader.Find("MADFINGER/Characters/BRDFLit  (Supports Backlight)");
            UpdateRenderers();
            if (!lookupTexture)
            {
                Preview();
            }
        }
    }

    public void Update()
    {
        if (Application.isEditor)
        {
            UpdateRenderers();
            SetupShader(_shader, lookupTexture);

            if (_internallyCreatedTexture != lookupTexture)
            {
                DestroyImmediate(_internallyCreatedTexture);
            }
        }
    }

    public void Preview()
    {
        UpdateRenderers();
        UpdateBRDFTexture(32, 64);
    }

    public void Bake()
    {
        UpdateRenderers();
        UpdateBRDFTexture(lookupTextureWidth, lookupTextureHeight);
    }

    void UpdateRenderers()
    {
        if (affectChildren)
        {
            _renderers = gameObject.GetComponentsInChildren<Renderer>(true);
        }
        else
        {
            _renderers = new Renderer[] { gameObject.GetComponent<Renderer>() };
        }
    }

    void SetupShader(Shader shader, Texture2D brdfLookupTex)
    {
        brdfLookupTex.wrapMode = TextureWrapMode.Clamp;

        foreach (Renderer r in _renderers)
        {
            foreach (Material mat in r.sharedMaterials)
            {
                if (shader && mat.shader != shader)
                {
                    mat.shader = shader;
                }

                if (brdfLookupTex != null)
                {
                    mat.SetTexture("_BRDFTex", brdfLookupTex);
                }

                // Background is 1000, Geometry is 2000, Transparent is 3000 and Overlay is 4000
                mat.renderQueue = 2000 + offsetRenderQueue;
            }
        }
    }

    Color PixelFunc(in float NdotL, in float NdotH)
    {
        // pseudo metalic diffuse falloff
        float ndotl = NdotL * Mathf.Pow(NdotH, metalic);

        float modDiffuseIntensity = (1.0f + metalic * 0.25f) * Mathf.Max(0.0f, diffuseIntensity - (1.0f - NdotH) * metalic);

        // diffuse tri-light
        var t0 = Mathf.Clamp01(Mathf.InverseLerp(-wrapAround, 1.0f, ndotl * 2.0f - 1.0f));
        var t1 = Mathf.Clamp01(Mathf.InverseLerp(-1.0f, Mathf.Max(-0.99f, -wrapAround), ndotl * 2.0f - 1.0f));
        var diffuse = modDiffuseIntensity * Color.Lerp(backColor, Color.Lerp(fillColor, keyColor, t0), t1);

        // Blinn-Phong specular (with energy conservation)
        float n = specularShininess * 128.0f;
        float energyConservationTerm = ((n + 2) * (n + 4)) / (8 * Mathf.PI * (Mathf.Pow(2.0f, -n / 2.0f) + n)); // by ryg
        //var energyConservationTerm : float = (n + 8) / (8 * Mathf.PI); // from Real-Time Rendering

        var specular = specularIntensity * energyConservationTerm * Mathf.Pow(NdotH, n);

        // Fresnel reflection (Schlick approximation)
        var fresnelR0 = Mathf.Lerp(0.3f, -1.0f, fresnelSharpness);
        var fresnelTerm = fresnelIntensity * Mathf.Max(0.0f, fresnelR0 + (1.0f - fresnelR0) * Mathf.Pow(1.0f - NdotH, 5.0f));

        // pseudo translucency (view dependent)
        float t = 0.5f * translucency * Mathf.Clamp01(1.0f - NdotH) * Mathf.Clamp01(1.0f - ndotl);

        //var c = Color(0,0,0, specular);
        var c = diffuse * intensity + fresnelReflectionColor * fresnelTerm + translucentColor * t + new Color(0, 0, 0, specular);
        return c * intensity;

    }

    void FillPseudoBRDF(Texture2D tex)
    {
        float width = tex.width;
        float height = tex.height;

        for (int y = 0; y < height; ++y)
        {
            for (int x = 0; x < width; ++x)
            {
                float NdotL = x / width;
                float NdotH = y / height;

                Color c = PixelFunc(NdotL, NdotH);
                tex.SetPixel(x, y, c);
            }
        }
    }

    void UpdateBRDFTexture(int width, int height)
    {
        Texture2D tex;
        if (lookupTexture == _internallyCreatedTexture && lookupTexture && lookupTexture.width == width && lookupTexture.height == height)
        {
            tex = lookupTexture;
        }
        else
        {
            if (lookupTexture == _internallyCreatedTexture)
            {
                DestroyImmediate(lookupTexture);
            }
            tex = new Texture2D(width, height, TextureFormat.ARGB32, false);
            _internallyCreatedTexture = tex;
        }

        FillPseudoBRDF(tex);
        tex.Apply();

        SetupShader(_shader, tex);
        lookupTexture = tex;
    }
}
