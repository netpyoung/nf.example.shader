노말의 앵글을 없에므로 메쉬간 평평한(Flat)효과를 얻을 수 있다.

속성을 변경하거나, 런타임에 변경할 수도 있다.

## 속성을 변경

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