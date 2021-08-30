# Vector

## [Swizzling](https://en.wikipedia.org/wiki/Swizzling_(computer_graphics))

벡터의 요소들을 이용 임의의 순서로 구성가능

``` hlsl
float4 A = float4(1, 2, 3, 4);

A.x     == 1
A.xy    == float2(1, 2)
A.wwxy  == float4(4, 4, 1, 2)
A.rgba  == float4(1, 2, 3, 4)
```

## 내적 외적

- 내적과 외적 공식.
- 내적과 외적을 시각적으로 생각할 수 있어야 함.
- 이거 이름 햇갈리기 쉬움.

### | 내적 | Dot Product   | Inner Product |

- 닷은 점이니까 모이는건 내적
- 점이니까 두개 모아서 하나가 됨.
- 하나로 모이니 두 벡터 사이의 각도를 구할 수 있음.
- 각도니까 cos연산 들어감.
- <https://rfriend.tistory.com/145>
- 교환법칙이 성립

``` ref
| 각도 | 값  |
| ---- | --- |
|    0 |  1  |
|   90 |  0  |
|  180 | -1  |
| -270 |  0  |

        1
        |
        |
0-------+------ 0
        |
        |
       -1
```

### | 외적 | Cross Product | Outer Product |

- 크로스는 삐죽하니까 외적으로 외울껏.
- X 니까 삐저나옴.
- X가 직각이니 수직 구할때 씀.
- <https://rfriend.tistory.com/146>
- 교환법칙 성립안함

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
