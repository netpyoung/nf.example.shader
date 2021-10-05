# Mesh

- <https://docs.unity3d.com/ScriptReference/Mesh.html>

``` cs
// (0,1) +----+ (1,1)
//       |    |
// (0,0) +----+ (1,0)
//
//     2 +----+ 3
//       |    |
//     0 +----+ 1


Mesh mesh = new Mesh();
Vector3[] vertices = new Vector3[4] {
    new Vector3(0, 0, 0),
    new Vector3(1, 0, 0),
    new Vector3(0, 1, 0),
    new Vector3(1, 1, 0)
};

int[] tris = new int[6] {
    // lower left triangle
    0, 2, 1,

    // upper right triangle
    2, 3, 1
};

Vector2[] uv = new Vector2[4] {
    new Vector2(0, 0),
    new Vector2(1, 0),
    new Vector2(0, 1),
    new Vector2(1, 1)
};

Vector3[] normals = new Vector3[4] {
    -Vector3.forward,
    -Vector3.forward,
    -Vector3.forward,
    -Vector3.forward
};

mesh.vertices = vertices;
mesh.triangles = tris;
mesh.uv = uv;
mesh.normals = normals;
```

## Topology

- <https://docs.unity3d.com/ScriptReference/MeshTopology.html>

| MeshTopology |
| ------------ |
| Points       |
| Lines        |
| LineStrip    |
| Triangles    |
| Quads        |

``` cs
MehsFilter mf = GetComponent<MeshFilter>();
mf.mesh.SetIndice(mf.mesh.GetIndices(0), MeshTopology.Points, 0);
```

``` cs
public void SetIndices(int[] indices, MeshTopology topology, int submesh, bool calculateBounds = true, int baseVertex = 0);
```

메쉬토폴로지를 변경시켜 좀 더 그럴듯한 효과를 얻을 수 있다.

## Ref

- <https://docs.unity3d.com/ScriptReference/Mesh.SetIndices.html>
