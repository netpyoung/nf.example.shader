# Rim Light

카메라 각도 * 모델 90 | 그림
카메라 각도 * 모델 180 |안그림

- 피격 연출에도 들어간다.

``` hlsl
half rim = 1 - NdotV;
half steppedRim = smoothstep(1.0 - _RimWidth, 1.0, rim);
```

# Ref

- [Unite '17 Seoul - 모바일 하드웨어에서 퀄리티있는 유니티 셰이더 구현](https://youtu.be/9B3BDsFxP6I?t=1074)
- [[0806 박민근] 림 라이팅(rim lighting)](https://www.slideshare.net/agebreak/0806-rim-lighting)
- http://cagetu.egloos.com/5883856
- [GDC2011 - Cinematic Character Lighting in STAR WARS: THE OLD REPUBLIC](https://www.gdcvault.com/play/1014360/Cinematic-Character-Lighting-in-STAR)
