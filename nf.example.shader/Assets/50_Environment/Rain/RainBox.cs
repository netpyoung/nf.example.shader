using UnityEngine;

public class RainBox : MonoBehaviour
{
    public RainManager _manager;
    Color _color = new Color(0.2f, 0.3f, 1.0f, 0.35f);
    private Transform _transform;

    public float _FallingSpeed = 1f;
    public float _MinY = 0f;
    

    private void Awake()
    {
        _manager = transform.parent.GetComponent<RainManager>();
        _transform = this.transform;
    }

    private void Update()
    {
        _transform.position -= Vector3.up * Time.deltaTime * _FallingSpeed;

        if (_transform.position.y + _manager.settings.areaHeight < _MinY)
        {
            _transform.position = _transform.position + Vector3.up * _manager.settings.areaHeight * 2.0f;
        }
    }

    public void OnDrawGizmos()
    {
        if (_manager != null)
        {
            Gizmos.color = _color;
            Gizmos.DrawWireCube(
                transform.position + transform.up * _manager.settings.areaHeight * 0.5f,
                new Vector3(_manager.settings.areaSize, _manager.settings.areaHeight, _manager.settings.areaSize)
            );
                
        }
    }
}
