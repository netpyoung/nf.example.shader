# URP (Universal Render Pipeline)

- 기존 Built-in(Legacy) 쉐이더의 include 경로 및 함수명등 바뀜
- SBR Batcher 사용가능하게 바뀜.
- 1패스 1라이트방식 => 1패스 16개 라이트 지원

## sample

``` hlsl
Varyings OUT;
ZERO_INITIALIZE(Varyings, OUT);

OUT.positionCS    = TransformObjectToHClip(IN.positionOS.xyz);
OUT.positionWS    = TransformObjectToWorld(IN.positionOS.xyz);
OUT.N             = TransformObjectToWorldNormal(IN.normal);
OUT.uv            = TRANSFORM_TEX(IN.uv, _MainTex);
OUT.fogCoord      = ComputeFogFactor(IN.positionOS.z);          // float
OUT.shadowCoord   = TransformWorldToShadowCoord(OUT.positionWS);// float4
```

``` hlsl
VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
OUT.shadowCoord = GetShadowCoord(vertexInput);
```

``` hlsl
Light mainLight = GetMainLight();
Light mainLight = GetMainLight(shadowCoord);

half3 ambient = SampleSH(IN.normal);

half3 cameraWS = GetCameraPositionWS();
```

``` hlsl
// GPU instancing
#pragma multi_compile_instancing

// Fog
#pragma multi_compile_fog

// Light & Shadow
#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
#pragma multi_compile _ _ADDITIONAL_LIGHTS
#pragma multi_compile _ _ADDITIONAL_LIGHTS_CASCADE
#pragma multi_compile _ _SHADOWS_SOFT

// LightMap
#pragma multi_compile _ DIRLIGHTMAP_COMBINED
#pragma multi_compile _ LIGHTMAP_ON
```

## SBR Batcher / GPU인스턴싱

SRP Batcher가 추가됨으로써, 동적오브젝트가 많아져도 좋은 퍼포먼스 유지하는게

- <https://docs.unity3d.com/Manual/GPUInstancing.html>

``` hlsl
// For SRP Batcher

CBUFFER_START(UnityPerMaterial)
...
CBUFFER_END
```

``` hlsl
// for GPU instancing

struct Attributes
{
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO // for VR
};

Varyings vert(Attributes IN)
{
    Varyings OUT;
    UNITY_SETUP_INSTANCE_ID(IN);
    UNITY_TRANSFER_INSTANCE_ID(IN, OUT); 
};

half4 frag(Varyings IN) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(IN); 
}
```

| SBR Batcher                  | GPU Instancing                                               |
|------------------------------|--------------------------------------------------------------|
| 동일한 메쉬 아니여도 가능    | 동일한 메쉬 상태                                             |
| CBUFFER_START // CBUFFER_END | UNITY_INSTANCING_BUFFER_START // UNITY_INSTANCING_BUFFER_END |

## hlsl

|                         |                                                              |
|-------------------------|--------------------------------------------------------------|
| Core.hlsl               | VertexPositionInputs, 스크린 UV, 포그                        |
| Common.hlsl             | 각종 수학관련 구현, Texture유틸, 뎁스계산 등                 |
| Lighting.hlsl           | 라이트구조체, Diffuse, Specular, GI(SH, lightmap)            |
| Shadows.hlsl            | 쉐도우맵 샘플링, 케스케이드 계산, ShadowCoord, Shadow Bias   |
| SpaceTransform.hlsl     | 각종 공간변환 행렬 정의                                      |
| EntityLighting.hlsl     | SH, ProveVolume, Lightmap                                    |
| ImageBasedLighting.hlsl | PBRjcnt IBL관련된 부분(GGX, Anisotropy, ImportanceSample 등) |

## com.unity.render-pipelines.core/ShaderLibrary

### Common.hlsl

``` hlsl
// com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl

#elif defined(SHADER_API_D3D11)
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/API/D3D11.hlsl"
```

## Macros.hlsl

``` hlsl
// com.unity.render-pipelines.core/ShaderLibrary/Macros.hlsl

#define PI          3.14159265358979323846 // PI
#define TWO_PI      6.28318530717958647693 // 2 * PI
#define FOUR_PI     12.5663706143591729538 // 4 * PI
#define INV_PI      0.31830988618379067154 // 1 / PI
#define INV_TWO_PI  0.15915494309189533577 // 1 / (2 * PI)
#define INV_FOUR_PI 0.07957747154594766788 // 1 / (4 * PI)
#define HALF_PI     1.57079632679489661923 // PI / 2
#define INV_HALF_PI 0.63661977236758134308 // 2 / PI
#define LOG2_E      1.44269504088896340736 // log2e
#define INV_SQRT2   0.70710678118654752440 // 1 / sqrt(2)
#define PI_DIV_FOUR 0.78539816339744830961 // PI / 4

#define TRANSFORM_TEX(tex, name) ((tex.xy) * name##_ST.xy + name##_ST.zw)
#define GET_TEXELSIZE_NAME(name) (name##_TexelSize)
```

| name##_ST | texture space 정보 |
|-----------|--------------------|
| x         | Tiling X           |
| y         | Tiling Y           |
| z         | Offset X           |
| w         | Offset Y           |

| name##_TexelSize | 텍스처의 크기 정보 |
|------------------|--------------------|
| x                | 1.0/width          |
| y                | 1.0/height         |
| z                | width              |
| w                | height             |

``` txt
(U ,V)

V
(0,1)       (1,1)
   +----+----+
   |    |    |
   +----+----+
   |    |    |
   +----+----+
(0,0)       (1,0) U
```

## API/(renderer).hlsl

|            |                      |
|------------|----------------------|
| tex2D      | SAMPLE_TEXTURE2D     |
| tex2Dlod   | SAMPLE_TEXTURE2D_LOD |
| texCUBE    | SAMPLE_TEXCUBE       |
| texCUBElod | SAMPLE_TEXCUBE_LOD   |

``` hlsl
// com.unity.render-pipelines.core/ShaderLibrary/API/D3D11.hlsl

#define CBUFFER_START(name) cbuffer name {
#define CBUFFER_END };

#define ZERO_INITIALIZE(type, name) name = (type)0;


#define TEXTURE2D(textureName)                Texture2D textureName
#define TEXTURE2D_ARRAY(textureName)          Texture2DArray textureName
#define TEXTURECUBE(textureName)              TextureCube textureName
#define SAMPLER(samplerName)                  SamplerState samplerName

#define SAMPLE_TEXTURE2D(textureName, samplerName, coord2)                               textureName.Sample(samplerName, coord2)
#define SAMPLE_TEXTURE2D_LOD(textureName, samplerName, coord2, lod)                      textureName.SampleLevel(samplerName, coord2, lod)

#define SAMPLE_TEXTURE2D_ARRAY(textureName, samplerName, coord2, index)                  textureName.Sample(samplerName, float3(coord2, index))
#define SAMPLE_TEXTURE2D_ARRAY_LOD(textureName, samplerName, coord2, index, lod)         textureName.SampleLevel(samplerName, float3(coord2, index), lod)

#define SAMPLE_TEXTURECUBE(textureName, samplerName, coord3)                             textureName.Sample(samplerName, coord3)
#define SAMPLE_TEXTURECUBE_LOD(textureName, samplerName, coord3, lod)                    textureName.SampleLevel(samplerName, coord3, lod)

#define SAMPLE_DEPTH_TEXTURE(textureName, samplerName, coord2)          SAMPLE_TEXTURE2D(textureName, samplerName, coord2).r
#define SAMPLE_DEPTH_TEXTURE_LOD(textureName, samplerName, coord2, lod) SAMPLE_TEXTURE2D_LOD(textureName, samplerName, coord2, lod).r
```

### Packing.hlsl

``` hlsl
// com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl
real3 UnpackNormal(real4 packedNormal)
```

## com.unity.render-pipelines.universal/ShaderLibrary/

### universal/ShaderLibrary/Core.hlsl

``` hlsl
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"

struct VertexPositionInputs
{
    float3 positionWS; // World space position
    float3 positionVS; // View space position
    float4 positionCS; // Homogeneous clip space position
    float4 positionNDC;// Homogeneous normalized device coordinates
};


struct VertexNormalInputs
{
    real3 tangentWS;
    real3 bitangentWS;
    float3 normalWS;
};

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderVariablesFunctions.hlsl"
```

### ShaderVariablesFunctions.hlsl

``` hlsl
// com.unity.render-pipelines.universal/ShaderLibrary/ShaderVariablesFunctions.hlsl

VertexPositionInputs GetVertexPositionInputs(float3 positionOS)
{
    VertexPositionInputs input;
    input.positionWS = TransformObjectToWorld(positionOS);
    input.positionVS = TransformWorldToView(input.positionWS);
    input.positionCS = TransformWorldToHClip(input.positionWS);

    float4 ndc = input.positionCS * 0.5f;
    input.positionNDC.xy = float2(ndc.x, ndc.y * _ProjectionParams.x) + ndc.w;
    input.positionNDC.zw = input.positionCS.zw;

    return input;
}

VertexNormalInputs GetVertexNormalInputs(float3 normalOS)
VertexNormalInputs GetVertexNormalInputs(float3 normalOS, float4 tangentOS)

float3 GetCameraPositionWS()

float3 GetWorldSpaceViewDir(float3 positionWS)

real ComputeFogFactor(float z)

half3 MixFog(half3 fragColor, half fogFactor)

half LinearDepthToEyeDepth(half rawDepth)
```

### SpaceTransforms.hlsl

``` hlsl
// com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl

float3 TransformObjectToWorld(float3 positionOS) // OS > WS
float4 TransformObjectToHClip(float3 positionOS) // OS > HCS

float3 TransformWorldToView(float3 positionWS)   // WS > VS
float4 TransformWViewToHClip(float3 positionVS)  // VS > HCS

float3 TransformWorldToObject(float3 positionWS) // WS > OS

float3 TransformObjectToWorldDir(float3 dirOS, bool doNormalize = true) // normalOS > normalWS

```

## Varaiable

| [_ProjectionParams](https://docs.unity3d.com/Manual/SL-UnityShaderVariables.html) |                                         |
|-----------------------------------------------------------------------------------|-----------------------------------------|
| x                                                                                 | 1.0 (or –1.0 flipped projection matrix) |
| y                                                                                 | near plane                              |
| z                                                                                 | far plane                               |
| w                                                                                 | 1/FarPlane                              |

| [_ZBufferParams](https://docs.unity3d.com/Manual/SL-UnityShaderVariables.html) |              |
|--------------------------------------------------------------------------------|--------------|
| x                                                                              | 1 - far/near |
| y                                                                              | far / near   |
| z                                                                              | x / far      |
| w                                                                              | y / far      |

| _Time | Time since level load |
|-------|-----------------------|
| x     | t / 20                |
| y     | t                     |
| z     | t * 2                 |
| w     | t * 3                 |

| _SinTime | Sine of time |
|----------|--------------|
| x        | t / 8        |
| y        | t / 4        |
| z        | t / 2        |
| w        | t            |

| _CosTime | Cosine of time |
|----------|----------------|
| x        | t / 8          |
| y        | t / 4          |
| z        | t / 2          |
| w        | t              |

| unity_DeltaTime | Delta time   |
|-----------------|--------------|
| x               | dt           |
| y               | 1 / dt       |
| z               | smoothDt     |
| w               | 1 / smoothDt |
