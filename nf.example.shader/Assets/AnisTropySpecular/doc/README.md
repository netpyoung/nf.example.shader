# 헤어모델


    //   - Kajya-Kay 모델                -
    //     - 짧은머리는 괜춘. 빛의 산란효과는 별로
    //   - Steve Marschner 모델                      - SIGGRAPH 2003
    //     - 빛의 산란효과 개선(반사/내부산란/투과)
    //   - Scheuermann - Hair Rendering and Shading - GDC 2004
    
	
Kajya-Kay 모델                -
 - 짧은머리는 괜춘. 빛의 산란효과는 별로
https://blog.naver.com/sorkelf/40185948507


Steve Marschner 모델
- 빛의 산란효과 개선(반사/내부산란/투과)
https://blog.naver.com/sorkelf/40186644136

![./NTBFromUVs.png](./NTBFromUVs.png)

// Sphere
// T | r | 오른쪽
// B | g | 위쪽
// N | b | 직각

// 논문에서 T. 방향은 머리를향한 위쪽 방향.
// half3 T = normalize(IN.T);

// Sphere에서는 B가 위쪽이므로 B로해야 원하는 방향이 나온다.

더 알아볼것
- https://github.com/maajor/Marschner-Hair-Unity

```
float3 h = normalize(normalize(lightDir) + normalize(viewDir));
float NdotL = saturate(dot(Normal, lightDir));

float HdotA = dot(normalize(Normal + AnisoDir), h);
float aniso = max(0, sin(radians((HdotA + AnisoOffset) * 180)));

float spec = saturate(dot(Normal, h));
spec = saturate(pow(lerp(spec, aniso, AnisoMask), Gloss * 128) * Specular);

RGB = (LightColor * spec) * (atten * 2);
A = Alpha - Cutoff;

```