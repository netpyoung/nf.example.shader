[FORCE FIELD in Unity - SHADER GRAPH](https://www.youtube.com/watch?v=NiOGWZXBg4Y)
[Unity Shader Graph - Shield Effect Tutorial](https://www.youtube.com/watch?v=hTJqo1HeEOs)

https://github.com/Brackeys/Force-Field
https://github.com/vaxkun/ReinhardtLike-Shield-ShaderForge
https://github.com/WorldOfZero/UnityVisualizations
https://github.com/WorldOfZero/2D-Flat-Shape-Shader/blob/master/Assets/FlatSinShader.shader
https://github.com/yanagiragi/Unity_Shader_Learn
https://github.com/Toocanzs/Vertical-Billboard/blob/master/Toocanzs/Vertical%20Billboard/VerticalBillboard.cginc
https://github.com/Xiexe


Cast Shadow> Off
var ScreenDepth
ScreenDepth -= ScreenPosition.a
var edge = smoothstep(0, 1, 1 - ScreenDepth) + fresnel
texture * edge

거기다 마스킹으로 강조
https://docs.unity3d.com/Packages/com.unity.shadergraph@11.0/manual/Sphere-Mask-Node.html


``` hlsl
void Unity_SphereMask_float4(float4 Coords, float4 Center, float Radius, float Hardness, out float4 Out)
{
    Out = 1 - saturate((distance(Coords, Center) - Radius) / (1 - Hardness));
}
```