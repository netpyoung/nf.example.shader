
If w == 1, then the vector (x,y,z,1) is a position in space.
If w == 0, then the vector (x,y,z,0) is a direction

``` hlsl
// 순서주의
TransformedVector = TranslationMatrix * RotationMatrix * ScaleMatrix * OriginalVector;
```