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
    Subshader
    {
        // http://docs.unity3d.com/Manual/SL-SubshaderTags.html
        Tags
        {
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
            
            Tags
            {
            }

            // https://docs.unity3d.com/Manual/SL-Stencil.html
            Stencil
            {
            }
            
            // http://docs.unity3d.com/Manual/SL-CullAndDepth.html
            Cull <Back | Front | Off>
            ZTest <(Less | Greater | LEqual | GEqual | Equal | NotEqual | Always)>
            Offset <OffsetFactor>, <OffsetUnits>
            ZWrite <On | Off>

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

## Tags

Queue

| min  | default | max  |             | order               |
|------|---------|------|-------------|---------------------|
| 0    | 100     | 1499 | Background  | render First / back |
| 1500 | 2000    | 2399 | Geometry    |                     |
| 2400 | 2450    | 2699 | AlphaTest   |                     |
| 2700 | 3000    | 3599 | Transparent |                     |
| 3600 | 4000    | 5000 | Overlay     | render last / front |

IgnoreProjector

## Properties

``` hlsl
Float           | float  |
Range(min, max) | float  |

Vector          | float4 | (x, y, z, w)
Color           | float4 | (r, g, b, a)

2D              | float4 | "", "white", "black", "gray", "bump" // for     power of 2 size
Rect            | float4 | "", "white", "black", "gray", "bump" // for non-power of 2 size

Cube            | float4 | "", "white", "black", "gray", "bump"

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

## LihgtMode

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