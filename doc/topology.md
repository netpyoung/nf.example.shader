``` cs
MehsFilter mf = GetComponent<MeshFilter>();
mf.mesh.SetIndice(mf.mesh.GetIndices(0), MeshTopology.Points, 0);
```

 public void SetIndices(int[] indices, MeshTopology topology, int submesh, bool calculateBounds = true, int baseVertex = 0);

 https://docs.unity3d.com/ScriptReference/Mesh.SetIndices.html

https://docs.unity3d.com/ScriptReference/MeshTopology.html
 

|           |                              |
|-----------|------------------------------|
| Triangles | Mesh is made from triangles. |
| Quads     | Mesh is made from quads.     |
| Lines     | Mesh is made from lines.     |
| LineStrip | Mesh is a line strip.        |
| Points    | Mesh is made from points.    |

메쉬토폴로지를 변경시켜 좀 더 그럴듯한 효과를 얻을 수 있다.