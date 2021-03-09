using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[Serializable]
[VolumeComponentMenu("Custom Post-Processing/VolumePrintDepthMap")]
public class VolumePrintDepthMap : VolumeComponent, IPostProcessComponent
{
    [Tooltip("Enable effect")]
    public BoolParameter IsEnable = new BoolParameter(false);

    public bool IsActive() => IsEnable.value;

    public bool IsTileCompatible() => false;
}
