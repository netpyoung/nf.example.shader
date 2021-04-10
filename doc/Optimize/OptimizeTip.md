# Optimize tip

## from [Optimizing unity games (Google IO 2014)](https://www.slideshare.net/AlexanderDolbilov/google-i-o-2014)

- Shader.SetGlobalVector
- OnWillRenderObject(오브젝트가 보일때만), propertyID(string보다 빠름)

``` cs
void OnWillRenderObject()
{
    material.SetMatrix(propertyID, matrix);
}
```

## Tangent Space 라이트 계산

- 월드 스페이스에서 라이트 계산값과 탄젠트 스페이스에서 라이트 계산값과 동일.
- vertex함수에서 tangent space V, L을 구하고 fragment함수에 넘겨줌.
  - 월드 스페이스로 변환 후 계산하는 작업을 단축 할 수 있음
