# ShaderLab

``` hlsl
// http://docs.unity3d.com/Manual/SL-Shader.html
Shader <shader-name>
{

    HLSLINCLUDE
    // ...
    ENDHLSL

    // http://docs.unity3d.com/Manual/SL-Properties.html
    Properties
    {
        _PropertyName ("displayed name", <property-type>) = <property-default-value>
    }

    // http://docs.unity3d.com/Manual/SL-SubShader.html
    SubShader
    {
        // http://docs.unity3d.com/Manual/SL-SubshaderTags.html
        Tags
        {
            // 주의. Pass의 Tag랑 다름
            <tag-name> = <tag-value>
        }
        
        // http://docs.unity3d.com/Manual/SL-ShaderLOD.html
        LOD <lod-number>
            
        // http://docs.unity3d.com/Manual/SL-UsePass.html
        UsePass "Shader/Name"
        
        
        // http://docs.unity3d.com/Manual/SL-Pass.html
        Pass
        {
            Name "PassName"
            
            // https://docs.unity3d.com/Manual/SL-PassTags.html
            Tags
            {
                // 주의. Subshader의 Tag랑 다름
                <tag-name> = <tag-value>
            }

            // https://docs.unity3d.com/Manual/SL-Stencil.html
            Stencil
            {
            }
            
            // http://docs.unity3d.com/Manual/SL-CullAndDepth.html
            Cull <Back | Front | Off>
            ZTest <(Less | Greater | LEqual | GEqual | Equal | NotEqual | Always)> // default: LEqual 
            ZWrite <On | Off> // default: On 
            Offset <OffsetFactor>, <OffsetUnits>

            // http://docs.unity3d.com/Manual/SL-Blend.html
            Blend <SourceBlendMode> <DestBlendMode>
            BlendOp <colorOp> // Instead of adding blended colors together, carry out a different operation on them
            BlendOp <colorOp, alphaOp> // Same as above, but use different blend operation for color (RGB) and alpha (A) channels.
            AlphaToMask <On | Off>

            ColorMask <RGB | A | 0 | any combination of R, G, B, A>
         
            HLSLPROGRAM
            ENDHLSL
        }
    }

    // http://docs.unity3d.com/Manual/SL-Fallback.html
    Fallback Off
    Fallback <other-shader-name>

    // http://docs.unity3d.com/Manual/SL-CustomEditor.html
    // http://docs.unity3d.com/Manual/SL-CustomMaterialEditors.html
    CustomEditor <custom-editor-class-name>
}
```

## Properties

``` hlsl
Float           | float  |
Range(min, max) | float  |

Vector          | float4 | (x, y, z, w)
Color           | float4 | (r, g, b, a)

2D              | float4 | "", "white", "black", "gray", "bump" // for     power of 2 size
Rect            | float4 | "", "white", "black", "gray", "bump" // for non-power of 2 size

Cube            | float4 | "", "white", "black", "gray", "bump"

// 주의해야할게 2D/Rect/Cube는 linear설정 관계없이 sRGB로 된다.
// ex) pow(gray, 2.2);
```

| color string | RGBA            |
|--------------|-----------------|
| white        | 1,1,1,1         |
| black        | 0,0,0,0         |
| gray         | 0.5,0.5,0.5,0.5 |
| bump         | 0.5,0.5,1,0.5   |
| red          | 1,0,0,0         |

## Properties attributes

``` hlsl
[HideInInspector]
[NoScaleOffset]   - name##_ST 사용안할때
[Normal]          - 텍스쳐 설정 normal아니면 경고
[HDR]

[Gamma]           - indicates that a float/vector property is specified as sRGB value in the UI
(just like colors are), and possibly needs conversion according to color space used. See Properties in Shader Programs.
[PerRendererData]  - indicates that a texture property will be coming from per-renderer data in the form of a MaterialPropertyBlock. Material inspector changes the texture slot UI for these properties.

[MainTexture]
[MainColor]
```

## SubShader's Tags

``` hlsl
SubShader
{
    // http://docs.unity3d.com/Manual/SL-SubshaderTags.html
    Tags
    {
        // 주의. Pass의 Tag랑 다름
        "RenderPipeline" = "UniversalRenderPipeline"
        "RenderType" = "Opaque"
        "Queue" = "Geometry"
    }
}
```

``` hlsl
// ex) cutout() 셰이더
Tags
{
    "RenderPipeline" = "UniversalRenderPipeline"
    "Queue" = "AlphaTest"
    "RenderType" = "TransparentCutout"
    "IgnoreProjector" = "True"
}
```

### RenderPipeline

- <https://docs.unity3d.com/2021.1/Documentation/ScriptReference/Shader-globalRenderPipeline.html>

### Queue

렌더링 순서

`Geometry+1`, `Geometry-1` 과 같이 가중치 적용가능

| min  | default | max  |             | order               |
|------|---------|------|-------------|---------------------|
| 0    | 100     | 1499 | Background  | render First / back |
| 1500 | 2000    | 2399 | Geometry    |                     |
| 2400 | 2450    | 2699 | AlphaTest   |                     |
| 2700 | 3000    | 3599 | Transparent |                     |
| 3600 | 4000    | 5000 | Overlay     | render last / front |

### RenderType

- 그룹을 짓는것. 해당 그룹의 셰이더를 바꿔 랜더링 할 수 있음.
  - 예를들어 Opaque의 노말버퍼를 만들고 싶을때 `RenderWithShader(Shader shader, "Opaque")` 이런 식으로.. 
- <https://docs.unity3d.com/2021.1/Documentation/Manual/SL-ShaderReplacement.html>
- <https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.shadergraph/Editor/Generation/Enumerations/RenderType.cs>

| RenderType        |                                            |
|-------------------|--------------------------------------------|
| Opaque            | 대부분의 쉐이더                            |
| Transparent       | 투명한 쉐이더                              |
| TransparentCutout | 마스킹 된 투명 쉐이더(2pass 식물쉐이더 등) |
| Background        | Skybox 쉐이더                              |
| Overlay           | 후광(Halo), 플레어(Flare)                  |

### IgnoreProjector

- <https://docs.unity3d.com/Manual/class-Projector.html>
  - URP is not compatible with the Projector component. URP does not currently include an alternative solution.
- <https://github.com/Anatta336/driven-decals>
- <https://github.com/nyahoon-games/ProjectorForLWRP>

### Pass's Tags

``` hlsl
Pass
{
    // http://docs.unity3d.com/Manual/SL-SubshaderTags.html
    Tags
    {
        // 주의. SubShader의 Tag랑 다름
        "LightMode" = "UniversalForward"
    }
}
```

### LihgtMode

- <https://docs.unity3d.com/Packages/com.unity.render-pipelines.universal@10.3/manual/urp-shaders/urp-shaderlab-pass-tags.html>

| LightMode            | URP / Built-in |                                               |
|----------------------|----------------|-----------------------------------------------|
| UniversalForward     | URP            | Forward Rendering                             |
| UniversalGBuffer     | URP            | Deferred Rendering                            |
| UniversalForwardOnly | URP            | Forward & Deferred Rendering                  |
| Universal2D          | URP            | for 2D light                                  |
| ShadowCaster         | URP            | depth from the perspective of lights          |
| DepthOnly            | URP            | depth from the perspective of a Camera        |
| Meta                 | URP            | executes this Pass only when baking lightmaps |
| SRPDefaultUnlit      | URP (기본값)   | draw an extra Pass  (ex. Outline)             |
| Always               | Built-in       |                                               |
| ForwardAdd           | Built-in       |                                               |
| PrepassBase          | Built-in       |                                               |
| PrepassFinal         | Built-in       |                                               |
| Vertex               | Built-in       |                                               |
| VertexLMRGBM         | Built-in       |                                               |
| VertexLM             | Built-in       |                                               |

## Blend

대표적인 Blend 옵션 조합

|          |                  |                                               |
|----------|------------------|-----------------------------------------------|
| SrcAlpha | OneMinusSrcAlpha | Alpha Blend                                   |
| One      | One              | Additive(Without alpha, black is Transparent) |
| SrcAlpha | One              | Additive(With Alpha)                          |
| One      | OneMinusDstColor | Soft Additive                                 |
| DstColor | Zero             | Multiplicative                                |
| DstColor | SrcColor         | 2x Multiplicative                             |

## HLSLPROGRAM

``` hlsl
HLSLPROGRAM
// https://docs.unity3d.com/Manual/SL-ShaderPrograms.html
#pragma target 3.5

#pragma vertex   <func>
#pragma fragment <func>
#pragma geometry <func> // target 4.0
#pragma hull     <func> // target 5.0
#pragma domain   <func> // target 5.0


#pragma only_renderers      <renderers>
#pragma exclude_renderers   <renderers>
// renderers
// d3d11    |Direct3D 11/12
// glcore   |OpenGL 3.x/4.x
// gles     |OpenGL ES 2.0
// gles3    |OpenGL ES 3.x
// metal    |iOS
// /Mac     |Metal
// vulkan   |Vulkan
// d3d11_9x |Direct3D 11 9.x , as commonly used on WSA platforms
// xboxone  |Xbox One
// ps4      |PlayStation 4
// n3ds     |Nintendo 3DS
// wiiu     |Nintendo Wii U

#pragma multi_compile           ...
#pragma multi_compile_local     ...
#pragma shader_feature          ...
#pragma shader_feature_local    ...
#include 

ENDHLSL
```

## Built-in(Legacy)

``` hlsl
// Built-in(Legacy) 볼필요없는것.

CGINCLUDE
ENDCG

Pass
{
    Lighting On | Off
    Material { Material Block }
    SeparateSpecular On | Off
    Color Color-value
    ColorMaterial AmbientAndDiffuse | Emission

    Fog { Fog Block }

    AlphaTest (Less | Greater | LEqual | GEqual | Equal | NotEqual | Always) CutoffValue

    SetTexture textureProperty { combine options }

    GrabPass { } // _GrabTexture 
    GrabPass { "TextureName" } 

    CGPROGRAM
    #pragma surface surfaceFunction lightModel [optionalparams]


    // https://docs.unity3d.com/Manual/SL-ShaderPrograms.html
    // The following compilation directives don’t do anything and can be safely removed:
    #pragma glsl
    #pragma glsl_no_auto_normalization
    #pragma profileoption
    #pragma fragmentoption

    ENDCG
}
```
