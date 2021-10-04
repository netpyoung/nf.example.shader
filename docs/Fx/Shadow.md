# Shadow

TRANSFER_SHADOW
TRANSFER_SHADOW_CASTER

## 바닥그림자

| 이름         | 부하     | 형상 | 자기그림자 | 특징             |
|--------------|----------|------|------------|------------------|
| 원형         | 가장적음 | 평면 | X          | 원형텍스쳐       |
| 평면 투영    | 적음     | 평면 | X          | 평면에만         |
| 투영 텍스쳐  | 적당     | 지형 | X          | 물체 하나만      |
| 우선순위버퍼 | 큼       | 지형 | X          | 자기 그림자 없음 |
| 스텐실       | 큼       | 지형 | O          | 정점 수가 많음   |
| 깊이버퍼     | 큼       | 지형 | O          | 부분적 깜빡임    |

### 원형(circle) 그림자

- 그냥 원형 텍스쳐로

### 평면 투영 (Planar Projected) 그림자

- 그림자용 모델 따로 만들어서 셰이더 연산 절약.
- 캡슐로 몸통이랑 다리랑만 만들어서 대략적인 계산
  - [基于近似演算的Capsule Shadow（胶囊体阴影）](http://walkingfat.com/%e5%9f%ba%e4%ba%8e%e8%bf%91%e4%bc%bc%e6%bc%94%e7%ae%97%e7%9a%84capsule-shadow%ef%bc%88%e8%83%b6%e5%9b%8a%e4%bd%93%e9%98%b4%e5%bd%b1%ef%bc%89/)

### RenderTexture이용

- Shadow용 모델
  - LOD
- RenderTexture

### 스텐실

``` hlsl
float4 vPosWorld = mul( _Object2World, v.vertex);
float4 lightDirection = -normalize(_WorldSpaceLightPos0); 
float opposite = vPosWorld.y - _PlaneHeight;
float cosTheta = -lightDirection.y;	// = lightDirection dot (0,-1,0)
float hypotenuse = opposite / cosTheta;
float3 vPos = vPosWorld.xyz + ( lightDirection * hypotenuse );
o.pos = mul (UNITY_MATRIX_VP, float4(vPos.x, _PlaneHeight, vPos.z ,1));  

// 그림자 덧 방지
Stencil
{
    Ref 0
    Comp Equal
    Pass IncrWrap
    ZFail Keep
}
```

## 그림자맵 - 깊이버퍼

- 광원을 기준으로 물체의 상대적 거리(0 ~ 1)를 이미지로 저장.(0은 광원의 위치)
- <https://github.com/netpyoung/bs.introduction-to-shader-programming/blob/master/note/ch10.md>

## PSM(Perspective Shadow Map)

- <http://www-sop.inria.fr/reves/Marc.Stamminger/psm/>
- <http://x66vx.egloos.com/3808794>

## Ref

- [게임 개발 포에버: 실시간 그림자를 싸게 그리자! 평면상의 그림자 ( Planar Shadow)](https://gamedevforever.com/326)
- [[1023 박민수] 깊이_버퍼_그림자_1](https://www.slideshare.net/MoonLightMS/1023-1)
- [타카시 이마기레 - DirectX 9 셰이더 프로그래밍](https://www.hanbit.co.kr/store/books/look.php?p_code=B9447539340)
