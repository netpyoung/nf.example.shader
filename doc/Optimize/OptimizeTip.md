
- Shader.SetGlobalVector
- OnWillRenderObject(오브젝트가 보일때만), propertyID(string보다 빠름)
```
void OnWillRenderObject()
{
    material.SetMatrix(propertyID, matrix);
}
```

https://www.slideshare.net/AlexanderDolbilov/google-i-o-2014