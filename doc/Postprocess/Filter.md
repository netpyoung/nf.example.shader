# Filter / Blur

- 포스트프로세스니 ComputeShader와, 어차피 흐려지는 것이니 RenderPipeline을 이용하여 다운샘플링 된걸가지고 하는걸 추천.

``` hlsl
// 조심
// ref: https://docs.unity3d.com/Manual/SL-PlatformDifferences.html
// Flip sampling of the Texture: 
// The main Texture
// texel size will have negative Y).

#if UNITY_UV_STARTS_AT_TOP
if (_MainTex_TexelSize.y < 0)
{
    uv.y = 1-uv.y;
}
#endif
```

## Average / 평균값

- Mean Filter라 불리기도함
  - Median Filter도 있는데, 이는 평균값에 너무 벗어난 값은 포함하지 않음.
- N * N 블럭
- 주변 픽셀들을 더하고 평균값으로 칠함.

``` hlsl
// -1, -1 | 0, -1 | +1, -1
// -1,  0 | 0,  0 | +1,  0
// -1, +1 | 0, +1 | +1, +1

// weight
// 1, 1, 1,
// 1, 1, 1,
// 1, 1, 1
```

## Gaussian / 가우스

- N * N 블럭
- 보다 원본 이미지가 잘 살도록, 중심부에 가중치를 더 준다.

``` hlsl
// -1, -1 | 0, -1 | +1, -1
// -1,  0 | 0,  0 | +1,  0
// -1, +1 | 0, +1 | +1, +1

// weight
// Sigma: 1.0 | Kernel Size : 3
// 0.077847,    0.123317,   0.077847,
// 0.123317,    0.195346,   0.123317,
// 0.077847,    0.123317,   0.077847
```

- [Gaussian Kernel Calculator](http://dev.theomader.com/gaussian-kernel-calculator/)
- <https://www.sysnet.pe.kr/2/0/11623>
- <https://rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/>

## Bilateral / 쌍방

- 엣지를 보존하면서 노이즈를 제거

## Kawase / 카와세

- 대각선을 샘플.

``` hlsl
// -1, -1 |   -   | +1, -1
//    -   | 0,  0 |    -   
// -1, +1 |   -   | +1, +1

// weight
// 1/8 |  -  | 1/8
//  -  | 1/2 |  - 
// 1/8 |  -  | 1/8
```

- <https://github.com/JujuAdams/Kawase>
- [GDC2003 - Frame Buffer Postprocessing Effects in DOUBLE-S.T.E.A.L (Wreckless)](http://genderi.org/frame-buffer-postprocessing-effects-in-double-s-t-e-a-l-wreckl.html)
- Dual filtering
  - [SIGGRAPH2015 - Bandwidth-Efficient Rendering](https://community.arm.com/cfs-file/__key/communityserver-blogs-components-weblogfiles/00-00-00-20-66/siggraph2015_2D00_mmg_2D00_marius_2D00_notes.pdf)

## Radial / 방사형

- 중심에서 원형으로 뻗혀나가는 방사형 블러.
- <https://forum.unity.com/threads/radial-blur.31970/#post-209514>

## Zoom

- <https://blog.naver.com/mnpshino/221478999495>