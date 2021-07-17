using UnityEngine;

public class GrassBoomSpawnFromMouse : MonoBehaviour
{
    public Camera _MainCamera;
    public GameObject _RenderTargetParticle;

    private RaycastHit _raycastHit;
    
    void Update()
    {
        if (Input.GetMouseButtonDown(0))
        {
            if (Physics.Raycast(_MainCamera.ScreenPointToRay(Input.mousePosition), out _raycastHit))
            {
                GameObject RenderTextureParticle = Instantiate(_RenderTargetParticle, _raycastHit.point, Quaternion.identity);
                Destroy(RenderTextureParticle, 3f);
            }
        }
    }
}
