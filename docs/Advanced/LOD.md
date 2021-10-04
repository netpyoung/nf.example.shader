# LOD

- LOD : Level Of Detail

|           |                       | Level of detail (N은 0부터) |
| --------- | --------------------- | --------------------------- |
| tex2Dlod  | SAMPLE_TEXTURE2D_LOD  | N (밉맵 고정)               |
| tex2Dbias | SAMPLE_TEXTURE2D_BIAS | 현재 밉맵 + N               |


|                                 |                               |                             |
| ------------------------------- | ----------------------------- | --------------------------- |
| QualitySettings.lodBias         | LOD가 바뀌는 거리의 비율 조절 | 작을 수록 LOD가 빨리 바뀐다 |
| QualitySettings.maximumLODLevel | 최대 LOD레벨 지정             |                             |

``` cs
// ref: https://www.unity3dtips.com/unity-fix-blurry-textures-on-mipmap/

UnityEditor.EditorPrefs.SetBool("DeveloperMode", true);

// 인스펙터에 Debug-Internal로 들어가서
// Texture Settings > Mip Bias 부분 설정 가능
```

## 밉맵 날카롭게 만들기

- [밉맵 디테일 높이기](https://kblog.popekim.com/2013/06/blurrymipmap.html)
- DDS로 밉맵을 따로 제작해서 만들거나
- AssetPostprocessor를 이용해서 처리

``` txt
1. 밉맵 0으로부터 밉맵 1 생성 (bilinear filter)
2. 밉맵 1에 sharpening filter 적용
3. 2번 결과물로부터 밉맵 2 생성(bilinear filter)
4. 밉맵 2에 sharpening filter 적용
5. 밉맵 끝까지 만들때까지 반복...
```

<div class="juxtapose" data-animate="false">
  <img src="/ImgHosting1/ShaderExample/MipmapsSharper_before.jpg" data-label="LOD 2" />
  <img src="/ImgHosting1/ShaderExample/MipmapsSharper_after.jpg" data-label="LOD 2 - Sharppen" />
</div>

### AssetPostprocessor

``` cs
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
```

## HLOD

- HLOD : Hierarchical Level Of Detail
- [Unite2019 HLOD를 활용한 대규모 씬 제작 방법](https://www.slideshare.net/ssuser4635b2/unite2019-hlod)

## Ref

- <https://docs.unity3d.com/ScriptReference/AssetPostprocessor.OnPostprocessTexture.html>
- <https://zhuanlan.zhihu.com/p/413834301>
- <https://community.khronos.org/t/texture-lod-calculation-useful-for-atlasing/61475>