using UnityEngine;
using System;

#if UNITY_EDITOR
using UnityEditor;

#endif

public class SkyPlaneManager : MonoBehaviour
{

    [Serializable]
    public class SkyPlaneSettings
    {

        //   +  : Z_Top
        //  / \   
        // +   +: Z_Bottom
        // |---|: width

        public float SkyPlane_Z_Bottom = 0.0f;
        public float SkyPlane_Z_Top = 0.5f;
        public float SkyPlaneWidth = 10.0f;
        public int SkyPlaneResolution = 10;
        public int TextureRepeatCount = 4;
    }

    [SerializeField]
    public SkyPlaneSettings settings;
    public bool generateNewAssetsOnStart = false;

    void Start()
    {
#if UNITY_EDITOR
        if (generateNewAssetsOnStart)
        {
            Mesh m1 = CreateMesh(settings);

            AssetDatabase.StartAssetEditing();
            {
                AssetDatabase.CreateAsset(m1, $"Assets/50_Environment/_Sky/{gameObject.name}_LQ0.asset");
            }
            AssetDatabase.StopAssetEditing();
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();

            Debug.Log("Created new rain meshes in Assets/50_Environment/_Sky/");
        }
#endif
    }


    public Mesh[] preGennedMeshes;
    private int preGennedIndex = 0;
    public Mesh GetPreGennedMesh()
    {
        return preGennedMeshes[(preGennedIndex++) % preGennedMeshes.Length];
    }

    struct SkyPlaneData
    {
        public Vector3 position;
        public Vector2 uv;
    }

    Mesh CreateMesh(SkyPlaneSettings settings)
    {
        Mesh mesh = new Mesh();

        float quadSize = settings.SkyPlaneWidth / settings.SkyPlaneResolution;
        float radius = settings.SkyPlaneWidth / 2.0f;
        float constant = (settings.SkyPlane_Z_Top - settings.SkyPlane_Z_Bottom) / (radius * radius);
        float uvDelta = (float)settings.TextureRepeatCount / settings.SkyPlaneResolution;
        float halfSkyPlaneWidth = 0.5f * settings.SkyPlaneWidth;

        int pow2SkyPlaneResolution = (settings.SkyPlaneResolution + 1) * (settings.SkyPlaneResolution + 1);
        int vertCount = 6 * pow2SkyPlaneResolution;
        int trisCount = vertCount;


        Vector3[] verts = new Vector3[vertCount];
        Vector2[] uvs = new Vector2[vertCount];
        Vector3[] normals = new Vector3[vertCount];
        int[] tris = new int[trisCount];

        Vector3 position;
        Vector2 uv;
        SkyPlaneData[] skyPlaneData = new SkyPlaneData[pow2SkyPlaneResolution];
        int index = 0;
        for (int col = 0; col <= settings.SkyPlaneResolution; ++col)
        {
            for (int row = 0; row <= settings.SkyPlaneResolution; ++row)
            {
                // index
                // 1-3-5
                // 0-2-4
                position.x = -halfSkyPlaneWidth + (col * quadSize);
                position.y = -(2 * halfSkyPlaneWidth) + (quadSize * 0.5f) + (row * quadSize);
                position.z = (1f * settings.SkyPlane_Z_Top) - (constant * ((position.x * position.x) + (position.y * position.y)));

                uv.x = col * uvDelta;
                uv.y = row * uvDelta;

                skyPlaneData[index].position = position;
                skyPlaneData[index].uv = uv;
                index++;
            }
        }

        int i6 = 0;
        for (int col = 0; col < settings.SkyPlaneResolution; ++col)
        {
            for (int row = 0; row < settings.SkyPlaneResolution; ++row)
            {
                int index0 = col * (settings.SkyPlaneResolution + 1) + row;
                int index1 = col * (settings.SkyPlaneResolution + 1) + (row + 1);
                int index2 = (col + 1) * (settings.SkyPlaneResolution + 1) + row;
                int index3 = (col + 1) * (settings.SkyPlaneResolution + 1) + (row + 1);

                verts[i6 + 0] = skyPlaneData[index0].position;
                verts[i6 + 1] = skyPlaneData[index1].position;
                verts[i6 + 2] = skyPlaneData[index2].position;
                verts[i6 + 3] = skyPlaneData[index2].position;
                verts[i6 + 4] = skyPlaneData[index1].position;
                verts[i6 + 5] = skyPlaneData[index3].position;

                uvs[i6 + 0] = skyPlaneData[index0].uv;
                uvs[i6 + 1] = skyPlaneData[index1].uv;
                uvs[i6 + 2] = skyPlaneData[index2].uv;
                uvs[i6 + 3] = skyPlaneData[index2].uv;
                uvs[i6 + 4] = skyPlaneData[index1].uv;
                uvs[i6 + 5] = skyPlaneData[index3].uv;

                tris[i6 + 0] = i6 + 0;
                tris[i6 + 1] = i6 + 1;
                tris[i6 + 2] = i6 + 2;
                tris[i6 + 3] = i6 + 3;
                tris[i6 + 4] = i6 + 4;
                tris[i6 + 5] = i6 + 5;

                normals[i6 + 0] = Vector3.up;
                normals[i6 + 1] = Vector3.up;
                normals[i6 + 2] = Vector3.up;
                normals[i6 + 3] = Vector3.up;
                normals[i6 + 4] = Vector3.up;
                normals[i6 + 5] = Vector3.up;
            }
            i6 += 6;
        }


        mesh.vertices = verts;
        mesh.triangles = tris;
        mesh.normals = normals;
        mesh.uv = uvs;
        mesh.RecalculateBounds();

        return mesh;
    }
}
