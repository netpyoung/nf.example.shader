using UnityEngine;

[DisallowMultipleComponent]
[RequireComponent(typeof(MeshRenderer))]
public class FlowMappedBurn : MonoBehaviour
{
    MeshRenderer _mr;
    MaterialPropertyBlock _mpb;

    [SerializeField] Transform InteractiveTransform;
    void Awake()
    {
        _mr = GetComponent<MeshRenderer>();
        _mpb = new MaterialPropertyBlock();
    }

    void Update()
    {
        _mpb.SetVector("_InteractPosition", InteractiveTransform.position);
        _mr.SetPropertyBlock(_mpb);
    }
}
