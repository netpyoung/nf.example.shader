using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MatcapMapper : MonoBehaviour
{
    [SerializeField]
    float Duration = 1;
  
    [SerializeField]
    AnimationCurve ColorMulCurve = AnimationCurve.Constant(0, 1, 1);
    [SerializeField]
    Color ColorMul = Color.white;
    [SerializeField]
    float ColorMulScale = 1;
    int _idMultipleColor = Shader.PropertyToID("_MultipleColor");

    float acc = 0;
    Renderer renderer;
    Color originColor;
    void Start()
    {
        renderer = GetComponent<Renderer>();
    }

    void Update()
    {
        if (acc > Duration)
        {
            return;
        }

        if (acc == 0)
        {
            originColor = renderer.material.GetColor(_idMultipleColor);
        }
        acc += Time.deltaTime;
        if (acc > Duration)
        {
            renderer.material.SetColor(_idMultipleColor, originColor);
            return;
        }

        float curve = ColorMulCurve.Evaluate(acc);
        renderer.material.SetColor(_idMultipleColor, ColorMul * ColorMulScale * curve);
    }
}
