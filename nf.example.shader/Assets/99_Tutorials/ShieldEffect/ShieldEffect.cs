using UnityEngine;

public class ShieldEffect : MonoBehaviour
{
    Camera _camera;
    MeshRenderer _mr;
    MaterialPropertyBlock _mpb;
    RaycastHit _hit;

    void Awake()
    {
        _camera = Camera.main;
        _mr = transform.Find("Shield02").gameObject.GetComponent<MeshRenderer>();
        _mpb = new MaterialPropertyBlock();
    }


    // Update is called once per frame
    void Update()
    {
        Ray ray = _camera.ScreenPointToRay(Input.mousePosition);
        if (!Physics.Raycast(ray, out _hit))
        {
            return;
        }
        _mpb.SetVector("_PointPosition", _hit.point);
        _mr.SetPropertyBlock(_mpb);
    }
}
