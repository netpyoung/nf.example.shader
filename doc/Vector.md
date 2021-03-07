# Vector

## [Swizzling](https://en.wikipedia.org/wiki/Swizzling_(computer_graphics))

벡터의 요소들을 이용 임의의 순서로 구성가능

``` hlsl
float4 A = float4(1, 2, 3, 4);

A.x     == 1
A.xy    == float2(1, 2)
A.wwxy  == float4(4, 4, 1, 2)
```

## Matrix

If w == 1, then the vector (x,y,z,1) is a position in space.
If w == 0, then the vector (x,y,z,0) is a direction

``` hlsl
// 순서주의
TransformedVector = TranslationMatrix * RotationMatrix * ScaleMatrix * OriginalVector;
```

``` txt
// ref: https://www.3dgep.com/3d-math-primer-for-game-programmers-matrices/#Rotation_about_an_arbitrary_axis

이동행렬
|  1  0  0  x  |
|  0  1  0  y  |
|  0  0  1  z  |
|  0  0  0  1  |

스케일
|  x  0  0  0  |
|  0  y  0  0  |
|  0  0  z  0  |
|  0  0  0  1  |


X축 회전
|    1    0    0    0 |
|    0  cos -sin    0 |
|    0  sin  cos    0 |
|    0    0    0    1 |

Y축 회전
|  cos    0  sin    0 |
|    0    1    0    0 |
| -sin    0  cos    0 |
|    0    0    0    1 |

Z축 회전
|  cos -sin    0    0 |
|  sin  cos    0    0 |
|    0    0    1    0 |
|    0    0    0    1 |


임의의 N축 회전
s : sin
c : cos
ic: 1 - cos

| ic * NxNx + c      | ic * NxNy - s * Nz | ic * NzNx + s * Ny | 0 |
| ic * NxNy + s * Nz | ic * NyNy + c      | ic * NyNz - s * Nx | 0 |
| ic * NzNx - s * Ny | ic * NyNz + s * Nx | ic * NzNz + c      | 0 |
|                  0 |                  0 |                  0 | 1 |
```
