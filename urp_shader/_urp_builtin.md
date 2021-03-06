
- [Teo Dutra's From Built-in To URP](https://teodutra.com/unity/shaders/urp/graphics/2020/05/18/From-Built-in-to-URP/)

URP

- https://github.com/Unity-Technologies/UniversalRenderingExamples
- https://github.com/phi-lira/UniversalShaderExamples


## include
| Content         | Built-in        | URP                                                                       |
|-----------------|-----------------|---------------------------------------------------------------------------|
| Core            | Unity.cginc     | Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl     |
| Light           | AutoLight.cginc | Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl |
| Shadows         | AutoLight.cginc | Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl  |
| Surface shaders | Lighting.cginc  | None, but you can find a side project for this here                       |

``` hlsl
o.vertex = UnityObjectToClipPos(v.vertex);
=>
o.vertex = TransformObjectToHClip(v.vertex.xyz);

half4 c = tex2D(_MainTex, i.texcoord);
=>
float4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);

texCUBElod(Cubemap Object, float4(Reflection Vector, mipLevel))
=>
SAMPLE_TEXCUBE_LOD(Cubemap Object, Sample Reflection Vector, mipLevel)


half3 worldSpaceLightDir = normalize(_WorldSpaceLightPos0);
=>
Light mainLight = GetMainLight(i.shadowCoord);
```

## Variant Keyword

???

- https://blogs.unity3d.com/2018/05/14/stripping-scriptable-shader-variants/

|                             |  |
|-----------------------------|--|
| _MAIN_LIGHT_SHADOWS         |  |
| _MAIN_LIGHT_SHADOWS_CASCADE |  |
| _ADDITIONAL_LIGHTS_VERTEX   |  |
| _ADDITIONAL_LIGHTS          |  |
| _ADDITIONAL_LIGHT_SHADOWS   |  |
| _SHADOWS_SOFT               |  |
| _MIXED_LIGHTING_SUBTRACTIVE |  |

## Macro
| built-in                            | URP                          |
|-------------------------------------|------------------------------|
| UNITY_PROJ_COORD (a)                | 없음, 대신 a.xy / aw 사용    |
| UNITY_INITIALIZE_OUTPUT(type, name) | ZERO_INITIALIZE (type, name) |

## Shadow

Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl

| Built-in                          | URP                                                                    |
|-----------------------------------|------------------------------------------------------------------------|
| UNITY_DECLARE_SHADOWMAP(tex)      | TEXTURE2D_SHADOW_PARAM(textureName, samplerName)                       |
| UNITY_SAMPLE_SHADOW(tex, uv)      | SAMPLE_TEXTURE2D_SHADOW(textureName, samplerName, coord3)              |
| UNITY_SAMPLE_SHADOW_PROJ(tex, uv) | SAMPLE_TEXTURE2D_SHADOW(textureName, samplerName, coord4.xyz/coord4.w) |
| TRANSFER_SHADOW                   | TransformWorldToShadowCoord                                            |
| UNITY_SHADOW_COORDS(x)            | x                                                                      |
| SHADOWS_SCREEN                    | x                                                                      |


urp - GetShadowCoords - shadow

## Fog
com.unity.render-pipelines.universal/ShaderLibrary/ShaderVariablesFunctions.hlsl”.
| Built-in                      | URP                                                 |
|-------------------------------|-----------------------------------------------------|
| UNITY_TRANSFER_FOG(o, outpos) | o.fogCoord = ComputeFogFactor(clipSpacePosition.z); |
| UNITY_APPLY_FOG(coord, col)   | color = MixFog(color, i.fogCoord);                  |
| UNITY_FOG_COORDS(x)           | x                                                   |

## Texture/Sampler Declaration Macros 

| Built-in                                          | URP                                                                      |
|---------------------------------------------------|--------------------------------------------------------------------------|
| UNITY_DECLARE_TEX2D(name)                         | TEXTURE2D(textureName); SAMPLER(samplerName);                            |
| UNITY_DECLARE_TEX2D_NOSAMPLER(name)               | TEXTURE2D(textureName);                                                  |
| UNITY_DECLARE_TEX2DARRAY(name)                    | TEXTURE2D_ARRAY(textureName); SAMPLER(samplerName);                      |
| UNITY_SAMPLE_TEX2D(name, uv)                      | SAMPLE_TEXTURE2D(textureName, samplerName, coord2)                       |
| UNITY_SAMPLE_TEX2D_SAMPLER(name, samplername, uv) | SAMPLE_TEXTURE2D(textureName, samplerName, coord2)                       |
| UNITY_SAMPLE_TEX2DARRAY(name, uv)                 | SAMPLE_TEXTURE2D_ARRAY(textureName, samplerName, coord2, index)          |
| UNITY_SAMPLE_TEX2DARRAY_LOD(name, uv, lod)        | SAMPLE_TEXTURE2D_ARRAY_LOD(textureName, samplerName, coord2, index, lod) |

Important to note that SCREENSPACE_TEXTURE has become TEXTURE2D_X. If you are working on some screen space effect for VR in Single Pass Instanced or Multi-view modes, you must declare the textures used with TEXTURE2D_X. This macro will handle for you the correct texture (array or not) declaration. You also have to sample the textures using SAMPLE_TEXTURE2D_X and use UnityStereoTransformScreenSpaceTex for the uv.

## Helper 

| Built-in                                    | URP            |                                                                   |
|---------------------------------------------|----------------|-------------------------------------------------------------------|
| fixed Luminance (fixed3 c)                  | Luminance      | com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl          |
| fixed3 DecodeLightmap (fixed4 color)        | DecodeLightmap | com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl |
| float4 EncodeFloatRGBA (float v)            | X              |                                                                   |
| float DecodeFloatRGBA (float4 enc)          | X              |                                                                   |
| float2 EncodeFloatRG (float v)              | X              |                                                                   |
| float DecodeFloatRG (float2 enc)            | X              |                                                                   |
| float2 EncodeViewNormalStereo (float3 n)    | X              |                                                                   |
| float3 DecodeViewNormalStereo (float4 enc4) | X              |                                                                   |

decodeInstructions is used as half4(LIGHTMAP_HDR_MULTIPLIER, LIGHTMAP_HDR_EXPONENT, 0.0h, 0.0h) by URP

## Lighting

| Built-in                 | URP                                            |                                                               |
|--------------------------|------------------------------------------------|---------------------------------------------------------------|
| WorldSpaceLightDir       | TransformObjectToWorld(objectSpacePosition)    | com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl |
| ObjSpaceLightDir         | TransformWorldToObject(_MainLightPosition.xyz) | com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl |
| float3 Shade4PointLights | x                                              |                                                               |

URP -_MainLightPosition.xyz 
URP - half3 VertexLighting(float3 positionWS, half3 normalWS) - com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl
If you want to loop over all additional lights using GetAdditionalLight(...), you can query the additional lights count by using GetAdditionalLightsCount().

Built-in	URP	 
_LightColor0	_MainLightColor	Include “Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl”
_WorldSpaceLightPos0	_MainLightPosition	Include “Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl”
_LightMatrix0	Gone ? Cookies are not supported yet	 
unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0	In URP, additional lights are stored in an array/buffer (depending on platform). Retrieve light information using Light GetAdditionalLight(uint i, float3 positionWS)	Include “Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl”
unity_4LightAtten0	In URP, additional lights are stored in an array/buffer (depending on platform). Retrieve light information using Light GetAdditionalLight(uint i, float3 positionWS)	Include “Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl”
unity_LightColor	In URP, additional lights are stored in an array/buffer (depending on platform). Retrieve light information using Light GetAdditionalLight(uint i, float3 positionWS)	Include “Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl”
unity_WorldToShadow	float4x4 _MainLightWorldToShadow[MAX_SHADOW_CASCADES + 1] or _AdditionalLightsWorldToShadow[MAX_VISIBLE_LIGHTS]	Include “Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl


| LIGHTING_COORDS| x| |


## Vertex-lit Helper Functions ↑
Built-in	URP	 
float3 ShadeVertexLights (float4 vertex, float3 normal)	Gone. You can try to use UNITY_LIGHTMODEL_AMBIENT.xyz + VertexLighting(...)	For VertexLighting(...) include “Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl”

A bunch of utilities can be found in “Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl”.

## Screen-space Helper Functions ↑
Built-in	URP	 
float4 ComputeScreenPos (float4 clipPos)	float4 ComputeScreenPos(float4 positionCS)	Include “Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderVariablesFunctions.hlsl”
float4 ComputeGrabScreenPos (float4 clipPos)	Gone.


ComputeScreenPos deprecated - https://github.com/Unity-Technologies/Graphics/pull/2529
GetVertexPositionInputs().positionNDC 

## Depth

Built-in	URP	 
LinearEyeDepth(sceneZ)	LinearEyeDepth(sceneZ, _ZBufferParams)	Include “Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl”
Linear01Depth(sceneZ)	Linear01Depth(sceneZ, _ZBufferParams)	Include “Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl”

To use the camera depth texture, include “Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl” and the _CameraDepthTexture will be declared for you as well as helper the functions SampleSceneDepth(...) and LoadSceneDepth(...).

## etc
ShadeSH9(normal)	SampleSH(normal)	Include “Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl”
unity_ColorSpaceLuminance	Gone. Use Luminance()	Include “Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl”


-----------------------------------------------------------------------


그림자를 처리하기 위해서 그냥 float4 하나 넘기면 되는 거고, GetShadowCoord()로 좌표를 구하고, MainLightRealtimeShadow() 함수를 통해서 실제 attenuation을 구할 수 있다. 커스텀 라이팅 모델을 구현할 때는 이렇게 하면 되고, 만약 내장된 PBR 라이팅을 쓸거라면 InputData 구조체에 좌표를 넣어서 UniversalFragmentPBR()을 호출하면 된다.
- https://codingdad.me/2020/02/12/urp-porting-3/


| Built-in                                |   |                     |
|-----------------------------------------|---|---------------------|
| PerceptualRoughnessToSpecPower          | x |                     |
| FresnelTerm                             | x |                     |
| _SpecColor                              | x |                     |
| BlendNormals                            | x | CommonMaterial.hlsl |
| DotClamped                              | x |                     |
| unity_LightGammaCorrectionConsts_PIDiv4 | x |                     |
| UnityGlobalIllumiation                  | x |                     |
---------------------------------------------------------------------
여깃는건 쓰지말것
https://leegoonz.blog/
https://www.alanzucconi.com/tutorials/
 - https://alexanderameye.github.io/outlineshader
https://roystan.net/articles/toon-water.html - 물웅덩이
https://darkcatgame.tistory.com/84
https://www.cyanilux.com/recent/2/

https://github.com/hebory?before=Y3Vyc29yOnYyOpK5MjAyMC0xMS0wOVQyMjo0MToyOCswOTowMM4Oqhfn&tab=stars - https://blog.naver.com/cra2yboy/222236607952


- 툰쉐이더
  - https://musoucrow.github.io/2020/07/05/urp_outline/ 
  - https://kink3d.github.io/blog/2017/10/04/Physically-Based-Toon-Shading-In-Unity
    - https://github.com/Kink3d/kShading/blob/master/Shaders/ToonLit.shader
- 반사
  - https://github.com/Kink3d/kMirrors
- 모션블러
  - https://github.com/Kink3d/kMotion
- 월드 스페이스노말
  - https://github.com/Kink3d/kNormals
- Fast Subsurface Scattering in unity
  - https://www.alanzucconi.com/2017/08/30/fast-subsurface-scattering-2/

- 헤어 그림자
  - https://zhuanlan.zhihu.com/p/232450616


Bulit-in URP
GammaToLinearSpace Gamma22ToLinear com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl