using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[Serializable]
[VolumeComponentMenu("Custom Post-Processing/Volume_PrintDepthMap")]
public class Volume_PrintDepthMap : VolumeComponent, IPostProcessComponent
{
    [Tooltip("Enable effect")]
    public BoolParameter IsEnable = new BoolParameter(false);

    // bool operator==(VolumeParameter<T> lhs, T rhs) => lhs != null && lhs.value != null && lhs.value.Equals(rhs);
    public bool IsActive() => IsEnable == true;

    public bool IsTileCompatible() => false;
}
