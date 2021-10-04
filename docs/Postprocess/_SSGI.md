# SSGI

- SSGI / Screen Space Global Illumination
- Illumination : 조명

## 구현

- 반구 주변의 점으로 가려짐 정도(Occlusion factor) 계산
  - 성능상 샘플링 갯수를 줄이는게...
- 계산된 가려짐 정도를 블러(Blur)로 적당히 흐려지게 만들기
- 원본 텍스쳐에 적용

## Case

``` glsl
// [(X) SSGI 관련 정리 (소스 포함)](http://eppengine.com/zbxe/programmig/2985)
// - backup article: https://babytook.tistory.com/157

uniform sampler2D som;  // Depth texture 
uniform sampler2D rand; // Random texture
uniform sampler2D color; // Color texture

uniform vec2 camerarange = vec2(1.0, 1024.0);

float pw = 1.0/800.0*0.5;
float ph = 1.0/600.0*0.5; 

float readDepth(in vec2 coord) 
{ 
    if (coord.x<0||coord.y<0) return 1.0;
    float nearZ = camerarange.x; 
    float farZ =camerarange.y; 
    float posZ = texture2D(som, coord).x;  
    return (2.0 * nearZ) / (nearZ + farZ - posZ * (farZ - nearZ)); 
}  

vec3 readColor(in vec2 coord) 
{ 
    return texture2D(color, coord).xyz; 
}

float compareDepths(in float depth1, in float depth2) 
{ 
    float gauss = 0.0;
    float diff = (depth1 - depth2)*100.0; //depth difference (0-100)
    float gdisplace = 0.2; //gauss bell center
    float garea = 3.0; //gauss bell width

    //reduce left bell width to avoid self-shadowing
    if (diff<gdisplace) garea = 0.2;

    gauss = pow(2.7182,-2*(diff-gdisplace)*(diff-gdisplace)/(garea*garea));

    return max(0.2,gauss); 
} 

vec3 calAO(float depth,float dw, float dh, inout float ao) 
{ 
    float temp = 0;
    vec3 bleed = vec3(0.0,0.0,0.0);
    float coordw = gl_TexCoord[0].x + dw/depth;
    float coordh = gl_TexCoord[0].y + dh/depth;

    if (coordw  < 1.0 && coordw  > 0.0 && coordh < 1.0 && coordh  > 0.0)
    {
        vec2 coord = vec2(coordw , coordh);
        temp = compareDepths(depth, readDepth(coord));
        bleed = readColor(coord);
    }
    ao += temp;
    return temp*bleed; 
}  

void main(void) 
{ 
    //randomization texture:
    vec2 fres = vec2(20,20);
    vec3 random = texture2D(rand, gl_TexCoord[0].st*fres.xy);
    random = random*2.0-vec3(1.0);

    //initialize stuff:
    float depth = readDepth(gl_TexCoord[0]);
    vec3 gi = vec3(0.0,0.0,0.0); 
    float ao = 0.0;

    for(int i=0; i<8; ++i)
    { 
        //calculate color bleeding and ao:
        gi += calAO(depth,  pw, ph,ao); 
        gi += calAO(depth,  pw, -ph,ao); 
        gi += calAO(depth,  -pw, ph,ao); 
        gi += calAO(depth,  -pw, -ph,ao);

        //sample jittering:
        pw += random.x*0.0005;
        ph += random.y*0.0005;

        //increase sampling area:
        pw *= 1.4; 
        ph *= 1.4;   
    }        

    //final values, some adjusting:
    vec3 finalAO = vec3(1.0-(ao/32.0));
    vec3 finalGI = (gi/32)*0.6;

    gl_FragColor = vec4(readColor(gl_TexCoord[0])*finalAO+finalGI,1.0); 
}  
```

## Ref

- <https://www.slideshare.net/jangho/real-time-global-illumination-techniques>
- <https://forum.unity.com/threads/my-ssao-ssgi-prototype.78566/#post-521710>
- <https://github.com/demonixis/StylisticFog-URP/tree/master/Assets/StylisticFog-URP>
- <https://people.mpi-inf.mpg.de/~ritschel/SSDO/index.html>
- [用Unity SRP实现SSGI，和手机端的效果测试（一）](http://walkingfat.com/%e7%94%a8unity-srp%e5%ae%9e%e7%8e%b0ssgi%ef%bc%8c%e5%92%8c%e6%89%8b%e6%9c%ba%e7%ab%af%e7%9a%84%e6%95%88%e6%9e%9c%e6%b5%8b%e8%af%95%ef%bc%88%e4%b8%80%ef%bc%89/)
