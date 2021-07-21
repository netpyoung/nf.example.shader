using UnityEngine;

public class SnowDrawer : MonoBehaviour
{
    [SerializeField] public Material SnowMaterial;
    [SerializeField] public Material BrushAddMaterial;
    [SerializeField] public Texture2D BrushTexture;
    [SerializeField] public float BrushSize = 0.5f;
    
    RenderTexture _PaintTex;
    Rect _baseBrushRect;

    private void Awake()
    {
        _PaintTex = (RenderTexture)SnowMaterial.GetTexture("_PaintTex");

        this._baseBrushRect = new Rect(
            -(BrushTexture.width * BrushSize),
            _PaintTex.height - (BrushTexture.height * BrushSize),
            BrushTexture.width / (1/BrushSize * 0.5f),
            BrushTexture.height / (1 / BrushSize * 0.5f)
        );

        Texture2D clearTex = new Texture2D(1, 1);
        clearTex.SetPixel(0, 0, new Color(0, 0, 0, 1));
        clearTex.Apply();
        Graphics.Blit(clearTex, _PaintTex);
    }

    void Update()
    {
        if (!Input.GetMouseButton(0))
        {
            return;
        }

        Ray cast = Camera.main.ScreenPointToRay(Input.mousePosition);
        if (Physics.Raycast(cast, out RaycastHit hit))
        {
            Collider coll = hit.collider;
            if (coll != null)
            {
                Vector2 uv = hit.lightmapCoord;
                var offsetX = uv.x * _PaintTex.width;
                var offsetY = -(uv.y * _PaintTex.height);

                { // Render Texture
                    RenderTexture.active = _PaintTex;
                    GL.PushMatrix();
                    GL.LoadPixelMatrix(0, _PaintTex.width, _PaintTex.height, 0);
                    { // Draw Texture
                        Rect rect = _baseBrushRect;
                        rect.x += offsetX;
                        rect.y += offsetY;
                        Graphics.DrawTexture(rect, BrushTexture, BrushAddMaterial);
                    } // Draw Texture
                    GL.PopMatrix();
                    RenderTexture.active = null;
                } // Render Texture
            }
        }
    }
}
