using UnityEngine;

public class RainSplashBox : MonoBehaviour
{
    public RainSplashManager _manager;
    Color _color = new Color(0.5f, 0.5f, 0.65f, 0.5f);
    
    private void Awake()
    {
        _manager = transform.parent.GetComponent<RainSplashManager>();
    }

    public void OnDrawGizmos()
    {
        if (_manager != null)
        {
            Gizmos.color = _color;
            Gizmos.DrawWireCube(
                transform.position + transform.up * _manager.settings.areaSize * 0.5f,
                new Vector3(_manager.settings.areaSize, _manager.settings.areaSize, _manager.settings.areaSize)
            );
                
        }
    }
}
