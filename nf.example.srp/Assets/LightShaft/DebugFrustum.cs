using UnityEngine;

public class DebugFrustum : MonoBehaviour
{
    public Camera _camera;
    Vector3[] _frustumCorners = new Vector3[4];

    private void OnDrawGizmos()
    {
        if (_camera == null)
        {
            return;
        }
        _camera.CalculateFrustumCorners(
            new Rect(0, 0, 1, 1),
            _camera.farClipPlane,
            Camera.MonoOrStereoscopicEye.Mono,
            _frustumCorners
        );

        for (int i = 0; i < 4; ++i)
        {
            var worldSpaceCorner = _camera.transform.TransformVector(_frustumCorners[i]);
            Debug.DrawRay(_camera.transform.position, worldSpaceCorner, Color.blue);
        }

    }
}
