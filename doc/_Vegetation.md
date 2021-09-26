# Vegetation

- Mesh의 중앙에서 vertex사이의 거리 이용.
- 작은것은 r채널만 이용해서 흔들거려도 될듯

|     |                                 |
| --- | ------------------------------- |
| r   | the stiffness of leaves' edges  |
| g   | per-leaf phase variation        |
| b   | overall stiffness of the leaves |
| a   | precomputed ambient occlusion   |

## Ref

- <https://developer.nvidia.com/gpugems/gpugems3/part-iii-rendering/chapter-16-vegetation-procedural-animation-and-shading-crysis>
- https://docs.unity3d.com/Packages/com.unity.polybrush@1.0/manual/modes_color.html
  - [u: Polybrush Intro and Tutorial](https://youtu.be/JQyntL-Z5bM?t=448)
- <https://blogs.unity3d.com/kr/2018/06/29/book-of-the-dead-quixel-wind-scene-building-and-content-optimization-tricks/>
- <https://blogs.unity3d.com/2018/08/07/shader-graph-updates-and-sample-project/>
