# SRP(Scriptable Render Pipeline)

- [Unity SRP와 LWRP에 대한 모든 것!](https://www.youtube.com/watch?v=MuzLdCXoJ9I)
- [Dev Weeks: URP 셰이더 뜯어보기](https://www.youtube.com/watch?v=9K1uOihvNyg)

UniversalRenderPipelineAsset.asset 

// 기본 CameraTarget

```cs
MyRenderPipelineAsset : RenderPipelineAsset
{
    protected override IRenderPipeline InternalCreatePipeline();
}

MyRenderPiepline : RenderPipeline
{
    protected override void Render(ScriptableRenderContext context, Camera[] cameras)
    {
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

      var drawSettings = new DrawRendererSettings(camera, new ShaderPassName("ForwardBase"));

      var filterSettings = new FilterRenderersSettings(true) {
          renderQueueRange = RenderQueueRange.opaque
          // 투명(Opaque)
          // 반투명(Transparent)

          // layerMask
          // renderingLayerMask
      };
    }
}
```

``` shader
// LightMode 태그는 라이팅 파이프 라인에서 패스의 역할을 정의.

Tags { "LightMode" = "ForwardBase" }
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

CBUFFER_START(UnityPerMaterial) // 메터리얼별
CBUFFER_START(UnityPerDraw)     // draw별 - https://blogs.unity3d.com/kr/2019/02/28/srp-batcher-speed-up-your-rendering/

-------------------


// Custom RenderTarget


RenderTarget Id가 필요
``` cs
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

----------------------------------
 ``` cs
 var cmd = CommandBufferPool.Get(string name);
 CommandBufferPool.Release(cmd);
 ```

 -------------------------------------

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

-------------------------------------

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

https://docs.unity3d.com/Packages/com.unity.render-pipelines.universal@9.0/api/UnityEngine.Rendering.Universal.ScriptableRendererFeature.html

``` cs
- ScriptableRenderContext
- ScriptableRenderer (abstract class)
  - public abstract void Setup(ScriptableRenderContext context, ref RenderingData renderingData);

- ScriptableRendererFeature
RenderingData

RenderPassEvent
RenderTargetHandle
```