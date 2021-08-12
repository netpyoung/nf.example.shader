# SRP (Scriptable Render Pipeline)

- <https://github.com/cinight/CustomSRP/tree/master/Assets>
- <https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.universal/Runtime/UniversalRenderPipeline.cs>
  - <https://github.com/Unity-Technologies/Graphics/blob/53fed35b0ed491fda85d87c8b39a3175c40d7fc3/com.unity.render-pipelines.universal/Runtime/UniversalRenderPipeline.cs#L348>
- `_MainTex`로 화면을 받음.

## RenderPipelineAsset.asset

- 유니티에서 그래픽스 파이프 라인을 관리한다. 여러 `Renderer`를 가질 수 있다.

``` cs
// Edit> Project Settings> Scriptable Render Pipeline Settings
// 런타임 렌더파이프라인에셋 교체
public RenderPipelineAsset _renderPipelineAsset;
GraphicsSettings.renderPipelineAsset = _renderPipelineAsset;
```

``` cs
// 클래스를 만들어서 사용자 렌더파이프라인에셋 만들기
[CreateAssetMenu(menuName = "Rendering/CustomRenderPipelineAsset")]
public class CustomRenderPipelineAsset : RenderPipelineAsset
{
    protected override RenderPipeline CreatePipeline()
    {
        return new CustomRenderPipeline();
    }
}

public class CustomRenderPipeline : RenderPipeline
{
    protected override void Render(ScriptableRenderContext context, Camera[] cameras);
}
```

## RenderGraph

TODO

|                |        |                                            |                                                                                                                                   |
|----------------|--------|--------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------|
| RTHandles      | class  | RenderTexture API 감싼것                   | <https://docs.unity3d.com/Packages/com.unity.render-pipelines.core@12.0/api/UnityEngine.Rendering.RTHandles.html>                 |
| ComputeBuffers | class  | Compute Shader를 위한 GPU data buffer      | <https://docs.unity3d.com/ScriptReference/ComputeBuffer.html>                                                                     |
| RendererLists  | struct | 렌더링에 사용하는 셋팅같은 정보들 모아둔것 | <https://docs.unity3d.com/Packages/com.unity.render-pipelines.core@12.0/api/UnityEngine.Experimental.Rendering.RendererList.html> |

- <https://github.com/cinight/CustomSRP/tree/master/Assets/SRP0802_RenderGraph>

## Renderer.asset

- 여러 `Feature`들을 가질 수 있다

## [ScriptableRendererFeature.cs](https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.universal/Runtime/ScriptableRendererFeature.cs)

|                 |                                |
|-----------------|--------------------------------|
| Create          | 시리얼라이제이션할때(생성할때) |
| AddRenderPasses | 카메라 설정할때                |

- `Create`시 기본 pass를 만들고, 만들 pass를 `AddRenderPasses`가 호출되면 넘어오는 인자 `ScriptableRenderer renderer`를 이용하여 `renderer.EnqueuePass(pass)`로 패스를 넘겨준다.

## [ScriptableRenderPass.cs](https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.universal/Runtime/Passes/ScriptableRenderPass.cs)

- 여기서 CommandBuffer, RenderTexture 등을 이용하여 처리를 해준다.

|                 |                                                                   |
|-----------------|-------------------------------------------------------------------|
| Configure       | Pass가 실행되기 전에 호출된다                                     |
| Execute         | .renderPassEvent를 이용하여 해당 패스 이벤트가 발생하면 실행된다. |
| OnCameraCleanup | 과거 FrameCleanup. 카메라 렌더링이 끝나면 호출된다                |

| RenderPassEvent               |
|-------------------------------|
| BeforeRendering               |
| BeforeRenderingShadows        |
| AfterRenderingShadows         |
| BeforeRenderingPrepasses      |
| AfterRenderingPrePasses       |
| BeforeRenderingOpaques        |
| AfterRenderingOpaques         |
| BeforeRenderingSkybox         |
| AfterRenderingSkybox          |
| BeforeRenderingTransparents   |
| AfterRenderingTransparents    |
| BeforeRenderingPostProcessing |
| AfterRenderingPostProcessing  |
| AfterRendering                |

## Example

### RenderPipeline

``` hlsl
Pass
{
    Tags
    {
        // LightMode 태그는 라이팅 파이프 라인에서 패스의 역할을 정의.
        "LightMode" = "CustomLightMode"
    }
}

```

``` cs
[CreateAssetMenu(menuName = "Rendering/CustomRenderPipelineAsset")]
public class CustomRenderPipelineAsset : RenderPipelineAsset
{
    protected override RenderPipeline CreatePipeline()
    {
        return new CustomRenderPipeline();
    }
}

// ==========================================================================
public class CustomRenderPipeline : RenderPipeline
{
    CustomRenderer _renderer = new CustomRenderer();

    protected override void Render(ScriptableRenderContext context, Camera[] cameras)
    {
        foreach (Camera cam in cameras)
        {
            _renderer.Render(ref context, cam);
        }
    }
}

// ==========================================================================
public class CustomRenderer
{
    readonly static ShaderTagId unlitShaderTagId = new ShaderTagId("CustomLightMode");

    public void Render(ref ScriptableRenderContext context, Camera cam)
    {
        // ...
        context.Submit();                 // 실행
    }
}
```

```cs
context.SetupCameraProperties(camera); // cmd전에 설정해주자(빠른 지우기)
var cmd = new CommandBuffer();
cmd.ClearRenderTarget
context.ExecuteCommandBuffer(cmd); // enqueue cmd
cmd.Release();
context.Submit();                 // 실행
```

``` cs
var cmd = new CommandBuffer();
cmd.BeginSample(string sampleName); // profiler begin
cmd.EndSample(string sampleName);   // profiler end
```

``` cs
// 컬링
if (!CulllResults.GetCullingParameters(camera, out ScriptableCullingParameters cullingParams))
{
    continue;
}
CullResults cullingResults = context.Cull(ref cullingParams);

SortingSettings sortingSettings = new SortingSettings(cam);
DrawingSettings drawingSettings = new DrawingSettings(unlitShaderTagId, sortingSettings);
FilteringSettings filteringSettings = new FilteringSettings(RenderQueueRange.opaque);

context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);
context.DrawRenderers             // 렌더링
context.DrawSkybox(camera)        // Skybox
```


``` cs
// cs
var cmd = new CommandBuffer();
cmd.SetGlobalVector("_LightDir", new Vector4(0, 1, 0, 0));
context.ExecuteCommandBuffer(cmd);
cmd.Release();

// shader
CBUFFER_START(_Light) // CommandBuffer에서 전송됨
float4 _LightDir;
CBUFFER_END
```

- CBUFFER_START(UnityPerMaterial) // 메터리얼별
- CBUFFER_START(UnityPerDraw)     // draw별
- <https://blogs.unity3d.com/kr/2019/02/28/srp-batcher-speed-up-your-rendering/>

``` cs
/// Render Texture 사용.

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

## Ref

- <https://blogs.unity3d.com/2018/01/31/srp-overview/>
- <https://blogs.unity3d.com/kr/2019/02/28/srp-batcher-speed-up-your-rendering/>
- <https://docs.unity3d.com/Manual/ScriptableRenderPipeline.html>
- <https://docs.unity3d.com/Manual/srp-creating-render-pipeline-asset-and-render-pipeline-instance.html>
- <https://github.com/cinight/CustomSRP>
- [catlikecoding - Custom SRP](https://catlikecoding.com/unity/tutorials/custom-srp/)

- [2019 - Unity SRP와 LWRP에 대한 모든 것!](https://www.youtube.com/watch?v=MuzLdCXoJ9I)
- [2020 - Universal RenderPipeline의 Custom RenderPass를 활용하여 렌더링 기능을 구현해보자 Track1-2](https://www.youtube.com/watch?v=vtfe3UgDs0w)
- [2020 - Dev Weeks: URP 기본 구성과 흐름](https://www.youtube.com/watch?v=QRlz4-pAtpY)
  - [Dev Weeks 2020.5. 세션자료](http://www.unitysquare.co.kr/growwith/resource/form?id=83)
- [2020 - Dev Weeks: URP 셰이더 뜯어보기](https://www.youtube.com/watch?v=9K1uOihvNyg)
  - [Dev Weeks 2020.6. 세션자료](http://www.unitysquare.co.kr/growwith/resource/form?id=87)
