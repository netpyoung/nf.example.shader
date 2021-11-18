눈쌓기

월드 노말 기준으로

눈 각도

``` hlsl
float _SnowSize;
float _SnowHeight;
float3 _SnowDirOS = float4(0, 1, 0, 1);

float3 snowDirWS = TransformObjectToWorldDir(normalize(_SnowDirOS));
float3 N = TransformObjectToWorldNormal(IN.normalOS);
if (dot(N, snowDirWS) >= _SnowSize)
{
    IN.positionOS.xyz += (v.positionOS.xyz * _SnowHeight);
}
```

- http://blog.naver.com/plasticbag0/221436480475
- [KGC2013 -  Company of Heroes 2 (COH2) Rendering Technology: The cold facts of recreating the hardest winter conditions of World War 2](https://www.slideshare.net/proyZ/daniel-barrero-coh2renderingtech)
