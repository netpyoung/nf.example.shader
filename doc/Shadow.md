
## 유니티 

TRANSFER_SHADOW
TRANSFER_SHADOW_CASTER

[셰도우캐스터(ShadowCaster)를 활용한 그림자 생성 변경](https://blueasa.tistory.com/1139)



## 바닥그림자

### 원형(circle) 평면 그림자


- 그냥 텍스쳐로

### 바닥 그림자 - RenderTexture이용

- Shadow용 모델
  - LOD
- RenderTexture

### 메시 평면 그림자 - 스텐실

``` shader
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

## Ref.

- [게임 개발 포에버: 실시간 그림자를 싸게 그리자! 평면상의 그림자 ( Planar Shadow)](https://gamedevforever.com/326)
