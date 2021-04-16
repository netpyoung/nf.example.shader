# MatCap

- SEM(Spherical Environment Mapping)
  - MatCap(Material Capture) / Lit Sphere
- 환경을 텍스쳐에 맵핑하고, `뷰스페이스 노말`로 색을 얻어온다.
- 케릭터에 사용할때는 Diffuse용/Reflect용 맵캡을 이용하도록 하자

``` hlsl
// vert
float3 binormalOS = cross(IN.normalOS, IN.tangentOS.xyz) * IN.tangentOS.w * unity_WorldTransformParams.w;
float3x3 TBN_os = float3x3(IN.tangentOS.xyz, binormalOS, IN.normalOS);

OUT.TtoV0 = mul(TBN_os, UNITY_MATRIX_IT_MV[0].xyz);
OUT.TtoV1 = mul(TBN_os, UNITY_MATRIX_IT_MV[1].xyz);

// frag
half2 normalVS;
normalVS.x = dot(IN.tan0, normalTS);
normalVS.y = dot(IN.tan1, normalTS);
half2 uv_Matcap = normalVS * 0.5 + 0.5;

half3 matcapTex = SAMPLE_TEXTURE2D(_MatcapTex, sampler_MatcapTex, uv_Matcap).rgb;
```

``` hlsl
// vert
half2 normalVS;
normalVS.x = dot(UNITY_MATRIX_IT_MV[0].xyz, IN.normalOS);
normalVS.y = dot(UNITY_MATRIX_IT_MV[1].xyz, IN.normalOS);
OUT.uv_Matcap = normalVS * 0.5 + 0.5;

// vert
half3 normalWS = TransformObjectToWorldNormal(IN.normalOS);
half3 normalVS = normalize(TransformWorldToView(normalWS));
```

## 번외

- normalOS를 이용함으로써 View에 대해 변하는게 아닌 고정효과
  - [카메라 방향에 상관없는 Matcap 만들기](https://chulin28ho.tistory.com/351)

``` hlsl
OUT.uv_Matcap = normalOS.xy * 0.5 + 0.5;
```

## Ref

- MaCrea(MatCap 생성 도구) <http://www.taron.de/>
  - 사용법: [MaCrea introduction](https://vimeo.com/14030320)
- <https://en.wikipedia.org/wiki/Sphere_mapping>
- http://wiki.polycount.com/wiki/Spherical_environment_map
- <https://docs.microsoft.com/en-us/windows/win32/direct3d9/spherical-environment-mapping>
- [[Unite Seoul 2019] 최재영 류재성 - 일곱개의 대죄 : "애니메이션의 감성을 그대로＂와 “개발 최적화"](https://youtu.be/0LwlNVS3FJo?t=530)
