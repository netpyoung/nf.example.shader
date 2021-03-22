# SRP (Scriptable Render Pipeline)

- <https://blogs.unity3d.com/2018/01/31/srp-overview/>
- <https://blogs.unity3d.com/kr/2019/02/28/srp-batcher-speed-up-your-rendering/>

- <https://docs.unity3d.com/Manual/ScriptableRenderPipeline.html>
- [Custom SRP](https://catlikecoding.com/unity/tutorials/custom-srp/)

## reference

- [2019 - Unity SRP와 LWRP에 대한 모든 것!](https://www.youtube.com/watch?v=MuzLdCXoJ9I)
- [2020 - Universal RenderPipeline의 Custom RenderPass를 활용하여 렌더링 기능을 구현해보자 Track1-2](https://www.youtube.com/watch?v=vtfe3UgDs0w)
- [2020 - Dev Weeks: URP 기본 구성과 흐름](https://www.youtube.com/watch?v=QRlz4-pAtpY)
  - [Dev Weeks 2020.5. 세션자료](http://www.unitysquare.co.kr/growwith/resource/form?id=83)
- [2020 - Dev Weeks: URP 셰이더 뜯어보기](https://www.youtube.com/watch?v=9K1uOihvNyg)
  - [Dev Weeks 2020.6. 세션자료](http://www.unitysquare.co.kr/growwith/resource/form?id=87)

## Samples

- <https://github.com/cinight/CustomSRP>

## Example

```cs
[CreateAssetMenu(menuName = "CreateAsset/MyRenderPipeLine")]
MyRenderPipelineAsset : RenderPipelineAsset
{
    protected override IRenderPipeline InternalCreatePipeline();
}

MyRenderPiepline : RenderPipeline
{
    protected override void Render(ScriptableRenderContext context, Camera[] cameras)
    {
        context.SetupCameraProperties(camera); // cmd전에 설정해주자(빠른 지우기)
        var cmd = new CommandBuffer();
        cmd.ClearRenderTarget
        context.ExecuteCommandBuffer(cmd); // enqueue cmd
        cmd.Release();

        context.Submit();                 // 실행
    }

    void Sample()
    {
      if (!CulllResults.GetCullingParameters(camera, out ScriptableCullingParameters cullingParams))
      {
          continue;
      }
      CullResults cr = CullResults.Cull(ref cullingParams, context);

      context.DrawRenderers             // 렌더링
      context.DrawSkybox(camera)        // Skybox

      var drawSettings = new DrawRendererSettings(camera, new ShaderPassName("CustomLightMode"));

      var filterSettings = new FilterRenderersSettings(true) {
          renderQueueRange = RenderQueueRange.opaque
          // 투명(Opaque)
          // 반투명(Transparent)

          // layerMask
          // renderingLayerMask
      };
    }
}


var cmd = new CommandBuffer();
cmd.BeginSample(string sampleName); // profiler begin
cmd.EndSample(string sampleName);   // profiler end
```

``` hlsl
// LightMode 태그는 라이팅 파이프 라인에서 패스의 역할을 정의.

Tags { "LightMode" = "CustomLightMode" }
```

``` shader
var cmd = new CommandBuffer();
cmd.SetGlobalVector("_LightDir", new Vector4(0, 1, 0, 0));
context.ExecuteCommandBuffer(cmd);
cmd.Release();

CBUFFER_START(_Light) // CommandBuffer에서 전송됨
float4 _LightDir;
CBUFFER_END
```

- CBUFFER_START(UnityPerMaterial) // 메터리얼별
- CBUFFER_START(UnityPerDraw)     // draw별
- https://blogs.unity3d.com/kr/2019/02/28/srp-batcher-speed-up-your-rendering/

``` cs
// RenderTarget Id가 필요
TemporaryRTID = Shader.PropertyToID("CustomRenderTargetID");
RTID = new RenderTargetIdentifier(TemporaryRTID);

{
    var cmd = new CommandBuffer();
    // https://docs.unity3d.com/ScriptReference/Rendering.CommandBuffer.GetTemporaryRT.html
    // GetTemporaryRT(int nameID, int width, int height, int depthBuffer, FilterMode filter, RenderTextureFormat format, RenderTextureReadWrite readWrite, int antiAliasing, bool enableRandomWrite);
    // GetTemporaryRT(int nameID, RenderTextureDescriptor desc, FilterMode filter);
    cmd.GetTemporaryRT(TemporaryRTID, )
    cmd.SetRenderTarget(RTID);
    cmd.ClearRenderTarget;
    context.ExecuteCommandBuffer(cmd);
    cmd.Release();
}

{
    var cmd = new CommandBuffer();
    cmd.Blit(RTID, BuiltinRenderTextureType.CameraTarget);
    cmd.ReleaseTemporaryRT(TemporaryRTID);
    context.ExecuteCommandBuffer(cmd);
    cmd.Release();
}
```

 ``` cs
 var cmd = CommandBufferPool.Get(string name);
 CommandBufferPool.Release(cmd);
 ```

### ScriptableRenderPass

``` cs
DrawSkyboxPass : ScriptableRenderPass
OpaquePostProcessPass : ScriptableRenderPass
ScreenSpaceShadowResolvePass : ScriptableRenderPass
SetupForwardRenderingPass : ScriptableRenderPass
...

CullResults cr = CullResults.Cull(ref cullingParams, context);
InitializeRenderingData(settings, ref cameraData, ref cullResults, out var renderingData);
renderer.Setup(context, ref renderingData); // RenderPass 쌓기.
renderer.Execute(context, ref renderingData);
```

``` cs
public class MyScriptableRenderPass : ScriptableRenderPass
{
    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData);
}

public class MyScriptableRenderFeature : ScriptableRenderFeature
{
    MyScriptableRenderPass mPass;

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(mPass);
    }

    public override void Create()
    {
        mPass = new MyScriptableRenderPass();
    }
}
```

``` cs
public struct RenderingData
{
    public CullingResults cullResults;
    public CameraData cameraData;
    public LightData lightData;
    public ShadowData shadowData;
    public PostProcessingData postProcessingData;
    public bool supportsDynamicBatching;
    public PerObjectData perObjectData;
    public bool postProcessingEnabled;
}
```

- https://docs.unity3d.com/Packages/com.unity.render-pipelines.universal@9.0/api/UnityEngine.Rendering.Universal.ScriptableRendererFeature.html

``` cs
- ScriptableRenderContext
- ScriptableRenderer (abstract class)
  - public abstract void Setup(ScriptableRenderContext context, ref RenderingData renderingData);

- ScriptableRendererFeature
RenderingData

RenderPassEvent
RenderTargetHandle
```