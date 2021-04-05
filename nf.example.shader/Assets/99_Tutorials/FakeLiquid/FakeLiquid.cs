using UnityEngine;

[DisallowMultipleComponent]
public class FakeLiquid : MonoBehaviour
{
    [SerializeField] float MaxWobble = 0.03f;
    [SerializeField] float WobbleSpeed = 1f;
    [SerializeField] float Recovery = 1f;

    Material _material = null;
    Vector3 _lastPosition;
    Vector3 _lastRotation;
    float _wobbleAddX;
    float _wobbleAddZ;
    float _timeAcc = 0.5f;

    void Awake()
    {
        _material = GetComponent<Renderer>().material;
    }

    private void Update()
    {
        _timeAcc += Time.deltaTime;

        Vector3 positionVelocity = (_lastPosition - transform.position) / Time.deltaTime;
        Vector3 rotationVelocity = (transform.rotation.eulerAngles - _lastRotation) * 0.2f;

        _wobbleAddX += Mathf.Clamp((positionVelocity.x + rotationVelocity.z), -1, 1) * MaxWobble;
        _wobbleAddZ += Mathf.Clamp((positionVelocity.z + rotationVelocity.x), -1, 1) * MaxWobble;
        _wobbleAddX = Mathf.Lerp(_wobbleAddX, 0, Time.deltaTime * Recovery);
        _wobbleAddZ = Mathf.Lerp(_wobbleAddZ, 0, Time.deltaTime * Recovery);

        float pulse = Mathf.Sin(2 * Mathf.PI * WobbleSpeed * _timeAcc);
        _material.SetFloat("_WobbleX", pulse * _wobbleAddX);
        _material.SetFloat("_WobbleZ", pulse * _wobbleAddZ);

        _lastPosition = transform.position;
        _lastRotation = transform.rotation.eulerAngles;
    }
}
