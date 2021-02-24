using UnityEditor;
using UnityEngine;
using UnityEngine.UIElements;
using UnityEditor.UIElements;

// channel packing
// - https://github.com/phi-lira/SmartTexture
// - https://github.com/andydbc/unity-texture-packer

// channel split?
// Read/Write Enable : CPU / GPU메모리 사용 주의사항.

// Gamma decode / encode

public class Hello : EditorWindow
{
    [MenuItem("Window/UI Toolkit/Hello")]
    public static void ShowExample()
    {
        Hello wnd = GetWindow<Hello>();
        wnd.titleContent = new GUIContent("Hello");
    }

    Texture2D yy;

    public void CreateGUI()
    {
        // Each editor window contains a root VisualElement object
        VisualElement root = rootVisualElement;

        // VisualElements objects can contain other VisualElement following a tree hierarchy.
        VisualElement label = new Label("Hello World! From C#");
        root.Add(label);

        // Import UXML
        var visualTree = AssetDatabase.LoadAssetAtPath<VisualTreeAsset>("Assets/TextureViewer/Hello.uxml");
        VisualElement labelFromUXML = visualTree.Instantiate();
        root.Add(labelFromUXML);

        var styleSheet = AssetDatabase.LoadAssetAtPath<StyleSheet>("Assets/TextureViewer/Hello.uss");
        root.styleSheets.Add(styleSheet);

        var field = root.Q<ObjectField>("ObjectField");

        field.RegisterCallback<ChangeEvent<Object>>(x =>
        {
            var val = field.value as Texture2D;
            Debug.Log($"val {val}");
            if (val != null)
            {
                yy = val;
            }
        });

        var img = root.Q<Image>("image");
        
        var btn = root.Q<Button>("AddButton");
        btn.clicked += () =>
        {
            Debug.Log("hi");
            Debug.Log($"yy {yy}");

            if (this.yy != null)
            {
                Texture2D n = new Texture2D(yy.width, yy.height);
                var pixels = yy.GetPixels32();
                for (int i = 0; i < pixels.Length; ++i)
                {
                    pixels[i].r = 0;
                    pixels[i].g = 0;
                }
                n.SetPixels32(pixels);
                n.Apply();
                img.image = n;
            }
        };
    }
}