# Bloom

``` txt
- 원본
- 축소 (w/4, h/4)
  - 밝은부분
    - 블러적용
- 원본과 블러적용 더하기
```

``` txt
cropW = srcW - srcW / Scale
cropH = srcH - srcH / Scale
cutdownW = cropW / Scale
cutdownH = cropH / Scale

소스     | srcW, srcH
축소버퍼 | cutdownW cutdownH
휘도버퍼 | cutdownW + 2 cutdownH + 2 | LDR 데이터로 충분

- Scale을 4로 축소시키면서 축소버퍼의 복사로 픽셀과 텍셀이 1:1 대응함으로 무리없이 복사가능.
- 휘도버퍼에서 패딩은(+2)
  - 블러를 먹이거나 광선을 늘일 경우, 화면을 초과한 픽셀을 검은색으로 처리하기 위한 방법
  - 안하면 텍스쳐 끝부분이 밝으면, 바깥쪽이 모두 밝은것으로 계산되어 필요 이상으로 빛나게됨.
```

축소 R16G16B16A16
휘도 R8G8B8A8
블러 R8G8B8A8
늘리기 계단 줄일려면 R16G16B16A16// 속도라면 R8G8B8A8

https://docs.unity3d.com/ScriptReference/Material.html
mainTextureOffset
mainTextureScale


```
Properties
{
    // _MainTex("UI Texture", 2D) = "white" {} 
    // 위와 같이 DrawMesh시 Properties에 정의되어있으면 정의된 색깔("white")로 나와버림
}
```




``` cs
public static int ToPow2RoundUp(int x)
{
  if(x == 0)
  {
    return 0;
  }
  return MakeMSB(x - 1) + 1;
}

public static int MakeMSB(int x)
{
  // 0b_0000_0000_0000_0000_1000_0000_1000_1011
  // MakeMSB(0b_1000) => 0b_1111
  // MakeMSB(0b_1111) => 0b_1111

  x |= x >> 1;
  x |= x >> 2;
  x |= x >> 4;
  x |= x >> 8;
  x |= x >> 16;
  return x;
}
```

```
int topBloomWidth = width >> Properties.DownSampleLevel;
int topBloomHeight = height >> Properties.DownSampleLevel;

w = TextureUtil.ToPow2RoundUp( topBloomWidth), 
h = TextureUtil.ToPow2RoundUp( topBloomHeight), 

brightnessOffsetX = (w - topBloomWidth) / 2;
brightnessOffsetY = (h - topBloomHeight) / 2;				
```

## Cross

``` txt
- 원본
- 축소 (w/4, h/4)
  - 밝은부분
    - 블러
    - 6방향 늘이기(예제에선 카메라 기준)
    - 늘린것 합치기
- 원본과 합쳐진 늘려진것 더하기
```
