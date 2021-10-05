# CheatSheet

- based on [[built-in] UnityShadersCheatSheet.shader](https://gist.github.com/Split82/d1651403ffb05e912d9c3786f11d6a44)

``` hlsl
// Cheetsheet for URP

// ref: https://docs.unity3d.com/Manual/SL-Shader.html
Shader "Name"
{
    HLSLINCLUDE
    // ...
    ENDHLSL

    // ref: https://docs.unity3d.com/Manual/SL-Properties.html
    Properties
    {
        _Name ("display name", Float)               = number
        _Name ("display name", Int)                 = number
        _Name ("display name", Range (min, max))    = number
        _Name ("display name", Color)               = (number,number,number,number)
        _Name ("display name", Vector)              = (number,number,number,number)

        _Name ("display name", 2D)      = "default-ColorString" {} // power of 2
        _Name ("display name", Rect)    = "default-ColorString" {} // non-power of 2
        _Name ("display name", Cube)    = "default-ColorString" {}
        _Name ("display name", 3D)      = "default-ColorString" {}

        // ## Property Attribute
        // ref: https://docs.unity3d.com/ScriptReference/MaterialPropertyDrawer.html
        // |                                                                          |                                                                                                                                                                                                     |
        // | ------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
        // | [HideInInspector]                                                        | 머테리얼 인스펙터에서 표시안함                                                                                                                                                                      |
        // | [NoScaleOffset]                                                          | 텍스쳐의 tiling/offset 필드를 표시안함                                                                                                                                                              |
        // | [Normal]                                                                 | 텍스쳐 설정 normal아니면 경고                                                                                                                                                                       |
        // | [HDR]                                                                    | 텍스쳐 설정 HDR 아니면 경고                                                                                                                                                                         |
        // | [Gamma]                                                                  | indicates that a float/vector property is specified as sRGB value in the UI (just like colors are), and possibly needs conversion according to color space used. See Properties in Shader Programs. |
        // | [PerRendererData]                                                        | indicates that a texture property will be coming from per-renderer data in the form of a MaterialPropertyBlock. Material inspector changes the texture slot UI for these properties.                |
        // | [Toggle]                                                                 |                                                                                                                                                                                                     |
        // | [Toggle(ENABLE_FANCY)] _Fancy ("Fancy?", Float) = 0                      | Will set "ENABLE_FANCY" shader keyword when set.                                                                                                                                                    |
        // | [ToggleOff]                                                              |                                                                                                                                                                                                     |
        // | [ToggleOff(DISABLE_EXAMPLE_FEATURE)]                                     |                                                                                                                                                                                                     |
        // | [Enum(UnityEngine.Rendering.BlendMode)] _Blend ("Blend mode", Float) = 1 | blend modes selection.                                                                                                                                                                              |
        // | [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("ZTest", Float) = 0 |                                                                                                                                                                                                     |
        // | [Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull Mode", Int) = 0   |                                                                                                                                                                                                     |
        // | [KeywordEnum(None, Add, Multiply)] _Overlay ("Overlay mode", Float) = 0  | Display a popup with None,Add,Multiply choices. Each option will set _OVERLAY_NONE, _OVERLAY_ADD, _OVERLAY_MULTIPLY shader keywords.                                                                |
        // | [MainTexture]                                                            |                                                                                                                                                                                                     |
        // | [MainColor]                                                              |                                                                                                                                                                                                     |
        // | [Header(A group of things)]                                              |                                                                                                                                                                                                     |
        // | [PowerSlider(3.0)]                                                       |                                                                                                                                                                                                     |
        // | [IntRange]                                                               |                                                                                                                                                                                                     |
        
        // Later on in the shader’s fixed function parts, property values can be accessed using property name in square brackets: [name] e.g. Blend [_SrcBlend] [_DstBlend].

        // ## ColorString
        // "red"
        // "black"         ""
        // "white"
        // "gray"          "grey"
        // "linearGray"    "linearGrey"
        // "grayscaleRamp" "greyscaleRamp"
        // "bump"
        // "blackCube"
        // "lightmap"
        // "unity_Lightmap"
        // "unity_LightmapInd"
        // "unity_ShadowMask"
        // "unity_DynamicLightmap"
        // "unity_DynamicDirectionality"
        // "unity_DynamicNormal"
        // "unity_DitherMask"
        // "_DitherMaskLOD"
        // "_DitherMaskLOD2D"
        // "unity_RandomRotation16"
        // "unity_NHxRoughness"
        // "unity_SpecCube0"
        // "unity_SpecCube1"
    }

    // ref: https://docs.unity3d.com/Manual/SL-SubShader.html
    SubShader
    {
        // ref: https://docs.unity3d.com/Manual/SL-SubShaderTags.html
        Tags
        {
            "TagName1" = "Value1"
            "TagName2" = "Value2"
        }

        // Queue tag: 렌더링 순서 지정. `Geometry+1`, `Geometry-1` 과 같이 가중치 적용가능
        // | Queue       | [min,  max]   | default | order                | etc                      |
        // | ----------- | ------------- | ------- | -------------------- | ------------------------ |
        // | Background  | [0    , 1499] | 100     | render first -> back |                          |
        // | <Geometry>  | [1500 , 2399] | 2000    |                      | Opaque는 이쪽에          |
        // | AlphaTest   | [2400 , 2699] | 2450    |                      | AlphaTest는 이쪽에       |
        // | Transparent | [2700 , 3599] | 3000    | render back -> front | AlphaBlend는 이쪽에      |
        // | Overlay     | [3600 , 5000] | 4000    | render last -> front |                          |

        // RenderType tag : 그룹을 짓는것. 해당 그룹의 셰이더를 바꿔 랜더링 할 수 있음.
        
        // | RenderType        |                                            |
        // | ----------------- | ------------------------------------------ |
        // | Background        | Skybox 쉐이더                              |
        // | Opaque            | 대부분의 쉐이더                            |
        // | TransparentCutout | 마스킹 된 투명 쉐이더(2pass 식물쉐이더 등) |
        // | Transparent       | 투명한 쉐이더                              |
        // | Overlay           | 후광(Halo), 플레어(Flare)                  |

        // 기타 SubShader의 Tags
        // "DisableBatching"      = "(True | <False> | LODFading)"
        // "ForceNoShadowCasting" = "(True | <False>)"
        // "CanUseSpriteAtlas"    = "(<True> | False)"
        // "PreviewType"          = "(<Sphere> | Plane | Skybox)"

        // ref: https://docs.unity3d.com/Manual/SL-ShaderLOD.html
        LOD <lod-number>

        // ref: https://docs.unity3d.com/Manual/SL-UsePass.html
        // 주어진 이름의 셰이더의 (첫번째 SubShader의) 모든 패스들이 삽입됨.
        UsePass "Shader/Name"

        // ref: https://docs.unity3d.com/Manual/SL-Pass.html
        Pass
        {
            Name "Pass Name"

            // ref: https://docs.unity3d.com/Manual/SL-PassTags.html
            // 주의. `Pass의 Tag`는 `SubShader의 Tag`랑 다름
            Tags
            {
                "TagName1" = "Value1"
                "TagName2" = "Value2"
            }

            // LightMode tag : 
            // | LightMode            |                                               |
            // | -------------------- | --------------------------------------------- |
            // | <SRPDefaultUnlit>    | draw an extra Pass  (ex. Outline)    |
            // | UniversalForward     | Forward Rendering                             |
            // | UniversalGBuffer     | Deferred Rendering                            |
            // | UniversalForwardOnly | Forward & Deferred Rendering                  |
            // | Universal2D          | for 2D light                                  |
            // | ShadowCaster         | depth from the perspective of lights          |
            // | DepthOnly            | depth from the perspective of a Camera        |
            // | Meta                 | executes this Pass only when baking lightmaps |

            // ref: https://docs.unity3d.com/Manual/SL-Stencil.html
            Stencil
            {
            }

            // ## Render 설정 (기본값 <>)
            // ref: https://docs.unity3d.com/Manual/SL-CullAndDepth.html
            // ref: https://docs.unity3d.com/Manual/SL-Blend.html
            Cull      (<Back> | Front | Off)
            ZTest     (Less | Greater | <LEqual> | GEqual | Equal | NotEqual | Always)
            ZWrite    (<On> | Off)
            Blend     SourceBlendMode DestBlendMode
            Blend     SourceBlendMode DestBlendMode, AlphaSourceBlendMode AlphaDestBlendMode
            ColorMask (RGB | A | 0 | any combination of R, G, B, A)
            Offset    OffsetFactor, OffsetUnits

            HLSLPROGRAM
            #pragma vertex   name // compile function name as the vertex shader.
            #pragma fragment name // compile function name as the fragment shader.
            #pragma geometry name // compile function name as DX10 geometry shader. Having this option automatically turns on #pragma target 4.0, described below.
            #pragma hull     name // compile function name as DX11 hull shader. Having this option automatically turns on #pragma target 5.0, described below.
            #pragma domain   name // compile function name as DX11 domain shader. Having this option automatically turns on #pragma target 5.0, described below.

            // Other compilation directives:
            // #pragma target            name                  - which shader target to compile to. See Shader Compilation Targets page for details.
            // #pragma only_renderers    space separated names - compile shader only for given renderers. By default shaders are compiled for all renderers. See Renderers below for details.
            // #pragma exclude_renderers space separated names - do not compile shader for given renderers. By default shaders are compiled for all renderers. See Renderers below for details.
            // #pragma enable_d3d11_debug_symbols              - generate debug information for shaders compiled for DirectX 11, this will allow you to debug shaders via Visual Studio 2012 (or higher) Graphics debugger.
            // #pragma multi_compile_instancing
            // #pragma multi_compile_fog
            // #pragma multi_compile                           - for working with multiple shader variants.
            //         multi_compile_local
            //         multi_compile_vertex
            //         multi_compile_vertex_local
            //         multi_compile_fragment
            //         multi_compile_fragment_local
            // #pragma shader_feature                          - for working with multiple shader variants. (unused variants of shader_feature shaders will not be included into game build)
            //         shader_feature_local
            //         shader_feature_vertex
            //         shader_feature_vertex_local
            //         shader_feature_fragment
            //         shader_feature_fragment_local
            
          
            // | Property | Variable                                    |
            // | -------- | ------------------------------------------- |
            // | Float    | float _Name;                                |
            // | Int      | float _Name;                                |
            // | Range    | float _Name;                                |
            // | Color    | float _Name;                                |
            // | Vector   | float _Name;                                |
            // | 2D       | TEXTURE2D(_Name);    SAMPLER(sampler_Name); |
            // | Rect     | TEXTURE2D(_Name);    SAMPLER(sampler_Name); |
            // | Cube     | TEXTURECUBE(_Name);  SAMPLER(sampler_Name); |
            // | 3D       | TEXTURE3D(_Name);    SAMPLER(sampler_Name); |

            // 간단한 Vertex/Fragment Shader 예제.
            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);

            struct APPtoVS
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 colorVertex  : COLOR;
                float2 uv           : TEXCOORD0;
            };

            struct VStoFS
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                return mainTex;
            }

            // 멀티타겟용 (Deferred)
            void frag(    VStoFS IN,
                      out half4  outDiffuse        : SV_Target0,
                      out half4  outSpecSmoothness : SV_Target1,
                      out half4  outNormal         : SV_Target2,
                      out half4  outEmission       : SV_Target3)
            {
                // ...
            }
            ENDHLSL
        }
    }

    // ref : https://docs.unity3d.com/Manual/SL-Fallback.html
    Fallback "Diffuse"

    // ref: https://docs.unity3d.com/Manual/SL-CustomEditor.html
    // ref: https://docs.unity3d.com/Manual/SL-CustomMaterialEditors.html
    CustomEditor <custom-editor-class-name>
}
```
