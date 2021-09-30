# FlatShader

- 노말의 앵글을 없에므로 메쉬간 평평한(Flat)효과를 얻을 수 있다.
- 속성을 변경하거나, 런타임에 변경할 수도 있다.

## 속성을 변경

- https://gamedevelopment.tutsplus.com/articles/go-beyond-retro-pixel-art-with-flat-shaded-3d-in-unity--gamedev-12259

``` txt
fbx> Normals & Tangents > Normals> Calculate
fbx> Normals & Tangents > Smoothing Angle> 0
```

## 런타임

``` cs
void FlatShading ()
{
    MeshFilter mf = GetComponent<MeshFilter>();
    Mesh mesh = Instantiate (mf.sharedMesh) as Mesh;
    mf.sharedMesh = mesh;

    Vector3[] oldVerts = mesh.vertices;
    int[] triangles = mesh.triangles;
    Vector3[] vertices = new Vector3[triangles.Length];

    for (int i = 0; i < triangles.Length; i++) 
    {
        vertices[i] = oldVerts[triangles[i]];
        triangles[i] = i;
    }

    mesh.vertices = vertices;
    mesh.triangles = triangles;
    mesh.RecalculateNormals();
}
```

## Shader

- 그게 아니면 shader를 이용해도...
- [Unity로 실습하는 Shader (5) - Flat Shading](https://www.sysnet.pe.kr/2/0/11613)
- <https://catlikecoding.com/unity/tutorials/advanced-rendering/flat-and-wireframe-shading/>

``` hlsl
half3 x = ddx(IN.positionWS);
half3 y = ddy(IN.positionWS);

half3 N = normalize(-cross(x, y));
```
