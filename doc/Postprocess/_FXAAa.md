# FXAA (Fast Approximate Anti-Aliasing)

윤곽선을 부드럽게

Pixel의 contrast를 이용하여 Edge를 찾아 Edge 부분만 적절히 보간해주는 방식


- 명암 차이로 윤곽선을 얻어, 선택적으로 블렌드

- Luma : 감마 컬렉션이 적용된 Luminance

non-linear RGB를 인자로 취함


``` txt

- Luminance Conversion
  - 픽셀당 8방향의 Luma가 필요하니 미리 계산해서 alpha채널에 넣거나, 그냥 green그대로 쓰기(명암차는 green에 민감하니)
- Local Contrast Check
  - 4방(상하좌우) Luma 차이 계산
  - 차이가 미미하면 AA미적용.
    - early exit
- Vertical/Horizontal Edge Test
  - 8방중 나머지 4방(대각선)의 luma를 구해 수평, 수직으로 외곽선 성질 검출(Sobel필터 비슷하게)
- End-of-edge Search
  - 앞서구한 방향(수평 혹은 수직)으로 외곽선이 끝나는 양쪽 지점 검출()
  - 양쪽 지점에 대한 평균 luma계산
- 외곽선이 끝나는 점 사이에 있는 기준점에 대한 blend값 구함
- blend값을 이용하여 기준점에서 어느정도 떨어진 픽셀값을 반환
  - RenderTexture(이하 RT)는 Bilinear filtering된것을 이용
```

``` txt
// PASS_LUMINANCE
// Luminance Conversion
mainTex.a = FxaaLuma(saturate(mainTex.rgb));

struct LuminanceData {
    float m; // Center
    float n; // North
    float e; // East
    float s; // South
    float w; // West
    float highest;
    float lowest;
    float contrast;
};

struct EdgeData {
    bool isHorizontal;
    float pixelStep;
    float oppositeLuminance;
    float gradient;
};

// Local Contrast Check
LuminanceData l;
float lumaM = 
float lumaS = 
float lumaE = 
float lumaN = 
float lumaW = 
l.highest = max(max(max(max(l.n, l.e), l.s), l.w), l.m);
l.lowest  = min(min(min(min(l.n, l.e), l.s), l.w), l.m);
l.contrast = l.highest - l.lowest;
if (l.contrast < threshold)
{
    discard;
}

// Vertical/Horizontal Edge Test
EdgeData e;
float horizontal =
    abs(l.n + l.s - 2 * l.m) * 2
    + abs(l.ne + l.se - 2 * l.e)
    + abs(l.nw + l.sw - 2 * l.w);
float vertical =
    abs(l.e + l.w - 2 * l.m) * 2
    + abs(l.ne + l.nw - 2 * l.n)
    + abs(l.se + l.sw - 2 * l.s);
e.isHorizontal = horizontal >= vertical;

// End-of-edge Search
e.pixelStep = e.isHorizontal ? _MainTex_TexelSize.y : _MainTex_TexelSize.x;
float pLuminance = e.isHorizontal ? l.n : l.e;
float nLuminance = e.isHorizontal ? l.s : l.w;
float pGradient = abs(pLuminance - l.m);
float nGradient = abs(nLuminance - l.m);
if (pGradient < nGradient)
{
    e.pixelStep = -e.pixelStep;
    e.oppositeLuminance = nLuminance;
    e.gradient = nGradient;
}
else
{
    e.oppositeLuminance = pLuminance;
    e.gradient = pGradient;
}

// blend값 구하기
float2 uvEdge = uv;
float2 edgeStep;
if (e.isHorizontal)
{
    uvEdge.y += e.pixelStep * 0.5;
    edgeStep = float2(_MainTex_TexelSize.x, 0);
}
else
{
    uvEdge.x += e.pixelStep * 0.5;
    edgeStep = float2(0, _MainTex_TexelSize.y);
}

float edgeLuminance = (l.m + e.oppositeLuminance) * 0.5;
float gradientThreshold = e.gradient * 0.25;

float2 puv = uvEdge + edgeStep;
float pLuminanceDelta = SampleLuminance(puv) - edgeLuminance;
bool pAtEnd = abs(pLuminanceDelta) >= gradientThreshold;
for (int i = 0; i < 9 && !pAtEnd; i++)
{
    puv += edgeStep;
    pLuminanceDelta = SampleLuminance(puv) - edgeLuminance;
    pAtEnd = abs(pLuminanceDelta) >= gradientThreshold;
}

float2 nuv = uvEdge - edgeStep;
float nLuminanceDelta = SampleLuminance(nuv) - edgeLuminance;
bool nAtEnd = abs(nLuminanceDelta) >= gradientThreshold;

for (int i = 0; i < 9 && !nAtEnd; i++) {
    nuv -= edgeStep;
    nLuminanceDelta = SampleLuminance(nuv) - edgeLuminance;
    nAtEnd = abs(nLuminanceDelta) >= gradientThreshold;
}

float pDistance, nDistance;
if (e.isHorizontal) {
    pDistance = puv.x - uv.x;
    nDistance = uv.x - nuv.x;
}
else {
    pDistance = puv.y - uv.y;
    nDistance = uv.y - nuv.y;
}

float shortestDistance;
bool deltaSign;
if (pDistance <= nDistance) {
    shortestDistance = pDistance;
    deltaSign = pLuminanceDelta >= 0;
}
else {
    shortestDistance = nDistance;
    deltaSign = nLuminanceDelta >= 0;
}

if (deltaSign == (l.m - edgeLuminance >= 0)) {
    return 0;
}
return 0.5 - shortestDistance / (pDistance + nDistance);
// blend값을 이용하여 기준점에서 어느정도 떨어진 픽셀값을 반환

float finalBlend = max(pixelBlend, edgeBlend);
if (e.isHorizontal) {
    uv.y += e.pixelStep * finalBlend;
}
else {
    uv.x += e.pixelStep * finalBlend;
}
```

360 - fxaaConsole360TexExpBiasNegOne,fxaaConsole360TexExpBiasNegTwo ??


## Ref

- [FXAA WhitePaper - Nvidia - Timothy Lottes](https://developer.download.nvidia.com/assets/gamedev/files/sdk/11/FXAA_WhitePaper.pdf)
- <https://catlikecoding.com/unity/tutorials/advanced-rendering/fxaa/>
- <https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.high-definition/Runtime/PostProcessing/Shaders/FXAA.hlsl>
- [assetstore: FXAA Fast Approximate Anti-Aliasing](https://assetstore.unity.com/packages/vfx/shaders/fullscreen-camera-effects/fxaa-fast-approximate-anti-aliasing-3590?locale=ko-KR#content)
- [SIGGRAPH2011 - FXAA 3.11](http://iryoku.com/aacourse/downloads/09-FXAA-3.11-in-15-Slides.pdf)
  - <http://iryoku.com/aacourse/>
- [Implementing FXAA - Simon Rodriguez](http://blog.simonrodriguez.fr/articles/2016/07/implementing_fxaa.html)
  - [[번역] Implementing FXAA](https://scahp.tistory.com/68)

``` hlsl
// https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl
real Luminance(real3 linearRgb)
{
    return dot(linearRgb, real3(0.2126729, 0.7151522, 0.0721750));
}
```

``` hlsl
// 블루값은 거의 영향이 없기에 무시(연산 아낌)
// ref: [FXAA WhitePaper - Nvidia - Timothy Lottes](https://developer.download.nvidia.com/assets/gamedev/files/sdk/11/FXAA_WhitePaper.pdf)
float FxaaLuma(float3 rgb)
{
    return rgb.g * (0.587/0.299) + rgb.r;
}

```

|  |  |
|--|--|
|  |  |

``` txt
// 방향
 NW | N  | NE
  W | M  |  E
 SW | S  | SE

// 가중치
  1 | 2  |  1
  2 |    |  2
  1 | 2  |  1
```

FXAA_EDGE_THRESHOLD
The minimum amount of local contrast required to apply algorithm.
1/3 – too little
1/4 – low quality
1/8 – high quality
1/16 – overkill

FXAA_EDGE_THRESHOLD_MIN
Trims the algorithm from processing darks.
1/32 – visible limit
1/16 – high quality
1/12 – upper limit (start of visible unfiltered edges)