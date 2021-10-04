using System.IO;
using UnityEditor;
using UnityEngine;

public class MipmapsSharperImporter : AssetPostprocessor
{
    void OnPostprocessTexture(Texture2D texture)
    {
        if (!Path.GetFileNameWithoutExtension(assetPath).EndsWith("_sharppen"))
        {
            return;
        }

        if (texture.mipmapCount == 0)
        {
            return;
        }

        for (int mipmapLevel = 1; mipmapLevel < texture.mipmapCount; ++mipmapLevel)
        {
            ApplyBilinearFilter(texture, mipmapLevel);
            ApplySharpeningFilter(texture, mipmapLevel);
        }
        texture.Apply(updateMipmaps: false, makeNoLongerReadable: true);
    }

    void ApplyBilinearFilter(Texture2D texture, int currMipmapLevel)
    {
        int currMipmapWidth = texture.width / (1 << currMipmapLevel);
        int currMipmapHeight = texture.height / (1 << currMipmapLevel);
        Color[] currPixels = new Color[currMipmapWidth * currMipmapHeight];

        int prevMipmapLevel = currMipmapLevel - 1;
        int prevMipmapWidth = texture.width / (1 << prevMipmapLevel);
        Color[] prevPixels = texture.GetPixels(prevMipmapLevel);
        
        for (int y = 0; y < currMipmapHeight; ++y)
        {
            for (int x = 0; x < currMipmapWidth; ++x)
            {
                int px = 2 * x;
                int py = 2 * y;

                Color c00 = prevPixels[(py) * prevMipmapWidth + (px)];
                Color c10 = prevPixels[(py) * prevMipmapWidth + (px + 1)];
                Color c01 = prevPixels[(py + 1) * prevMipmapWidth + (px)];
                Color c11 = prevPixels[(py + 1) * prevMipmapWidth + (px + 1)];

                Color b0 = Color.Lerp(c00, c10, 0.5f);
                Color b1 = Color.Lerp(c01, c11, 0.5f);
                Color final = Color.Lerp(b0, b1, 0.5f);

                currPixels[y * currMipmapWidth + x] = final;
            }
        }
        texture.SetPixels(currPixels, currMipmapLevel);
    }

    private void ApplySharpeningFilter(Texture2D texture, int mipmapLevel)
    {
        float _Sharpness = 0.1f;
        Color[] pixels = texture.GetPixels(mipmapLevel);
        int mipmapWidth = texture.width / (1 << mipmapLevel);
        int mipmapHeight = texture.height / (1 << mipmapLevel);
        const int HALF_RANGE = 1;
        for (int y = 0; y < mipmapHeight; ++y)
        {
            for (int x = 0; x < mipmapWidth; ++x)
            {
                Color color = pixels[y * mipmapWidth + x];
                Color sum = Color.black;
                for (int i = -HALF_RANGE; i <= HALF_RANGE; i++)
                {
                    for (int j = -HALF_RANGE; j <= HALF_RANGE; j++)
                    {
                        sum += pixels[Mathf.Clamp(y + j, 0, mipmapHeight - 1) * mipmapWidth + Mathf.Clamp(x + i, 0, mipmapWidth - 1)];
                    }
                }
                Color sobel8 = color * Mathf.Pow(HALF_RANGE * 2 + 1, 2) - sum;
                Color addColor = sobel8 * _Sharpness;
                color += addColor;
                pixels[y * mipmapWidth + x] = color;
            }

        }
        texture.SetPixels(pixels, mipmapLevel);
    }
}
