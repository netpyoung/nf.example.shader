using UnityEngine;
using System;

#if UNITY_EDITOR
using UnityEditor;

#endif

public class RainManager : MonoBehaviour
{

    [Serializable]
    public class RainAreaSettings
    {
        public int numberOfParticles = 400;
        public float areaSize = 40.0f;
        public float areaHeight = 15.0f;
        public float particleSize = 0.2f;
        public float flakeRandom = 0.1f;
        public Transform cameraTransform;
        public int randSeed = -1;
    }

    [SerializeField]
    public RainAreaSettings settings;
    public bool generateNewAssetsOnStart = false;

    void Start()
    {
#if UNITY_EDITOR
        if (generateNewAssetsOnStart)
        {
            Mesh m1 = CreateMesh(settings, new Rand(settings.randSeed));

            AssetDatabase.StartAssetEditing();
            {
                AssetDatabase.CreateAsset(m1, $"Assets/50_Environment/Rain/{gameObject.name}_LQ0.asset");
            }
            AssetDatabase.StopAssetEditing();
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();

            Debug.Log("Created new rain meshes in Assets/50_Environment/Rain/");
        }
#endif
    }


    public Mesh[] preGennedMeshes;
    private int preGennedIndex = 0;
    public Mesh GetPreGennedMesh()
    {
        return preGennedMeshes[(preGennedIndex++) % preGennedMeshes.Length];
    }

    Mesh CreateMesh(RainAreaSettings settings, Rand rand)
    {
        Mesh mesh = new Mesh();

        Vector3 cameraRight = settings.cameraTransform.right;
        Vector3 cameraUp = (Vector3.up);
        Vector3 cameraForward = settings.cameraTransform.forward;

        int particleNum = settings.numberOfParticles;

        int vertCount = 4 * particleNum;
        int trisCount = 6 * particleNum;

        Vector3[] verts = new Vector3[vertCount];
        Vector2[] uvs = new Vector2[vertCount];
        Vector2[] uvs2 = new Vector2[vertCount];
        Vector3[] normals = new Vector3[vertCount];
        int[] tris = new int[trisCount];

        Vector3 position;
        int i4 = 0;
        int i6 = 0;
        for (int i = 0; i < particleNum; ++i)
        {
            position.x = settings.areaSize * (rand.value - 0.5f);
            position.y = settings.areaHeight * rand.value;
            position.z = settings.areaSize * (rand.value - 0.5f);

            float randVal = rand.value;
            float widthWithRandom = settings.particleSize * 0.215f;// + rand * flakeRandom;
            float heightWithRandom = settings.particleSize + randVal * settings.flakeRandom;
            Vector3 w = cameraRight * widthWithRandom;
            Vector3 h = cameraUp * heightWithRandom;

            verts[i4 + 0] = position - w - h;
            verts[i4 + 1] = position + w - h;
            verts[i4 + 2] = position - w + h;
            verts[i4 + 3] = position + w + h;

            // 2 3
            // 0 1
            uvs[i4 + 0] = Vector2.zero;  // 0, 0
            uvs[i4 + 1] = Vector2.right; // 1, 0
            uvs[i4 + 2] = Vector2.up;    // 0, 1
            uvs[i4 + 3] = Vector2.one;   // 1, 1

            Vector2 uv2 = new Vector2(rand.Range(-2, 2) * 4.0f, rand.Range(-1, 1) * 1.0f);
            uvs2[i4 + 0] = uv2;
            uvs2[i4 + 1] = uv2;
            uvs2[i4 + 2] = uv2;
            uvs2[i4 + 3] = uv2;

            normals[i4 + 0] = -cameraForward;
            normals[i4 + 1] = -cameraForward;
            normals[i4 + 2] = -cameraForward;
            normals[i4 + 3] = -cameraForward;

            // 2 
            // 0 1
            tris[i6 + 0] = i4 + 0;
            tris[i6 + 1] = i4 + 2;
            tris[i6 + 2] = i4 + 1;
            // 2 3
            //   1
            tris[i6 + 3] = i4 + 2;
            tris[i6 + 4] = i4 + 3;
            tris[i6 + 5] = i4 + 1;

            i4 += 4;
            i6 += 6;
        }

        mesh.vertices = verts;
        mesh.triangles = tris;
        mesh.normals = normals;
        mesh.uv = uvs;
        mesh.uv2 = uvs2;
        mesh.RecalculateBounds();

        return mesh;
    }
}
