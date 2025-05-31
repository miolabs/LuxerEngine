# LuxerEngine

*A lightweight, modular Swift engine that scales from head-less logic to full Metal real-time graphics.*

![Swift 6.1](https://img.shields.io/badge/Swift-6.1-orange)
![Modular](https://img.shields.io/badge/Architecture-Modular-informational)

---

## 1 · Package Layout

| Package | Depends On | What it contains | Typical use-case |
|---------|------------|------------------|------------------|
| **`LuxerEngine-Core`** | – | Scene graph, component system, plugin registry, maths, asset helpers **with _zero_ rendering-API imports** | Scripting, server sims, or as a base for any GPU backend |
| **`LuxerEngine-Metal`** | Core + MetalKit | `MetalRenderDevice`, `MetalRenderEngine`, `MetalView`, default shaders | iOS / macOS / visionOS apps that render with Metal |
| **`LuxerEngine`** (umbrella) | Core + Metal | Re-exports both; defaults to Metal on Apple platforms | Most apps – single import |

Planned sibling back-ends: `LuxerEngine-OpenGL`, `LuxerEngine-Vulkan`, `LuxerEngine-DirectX`.

---

## 2 · Installing

### Swift Package Manager

Add the repo URL to your `Package.swift`:

```swift
.package(url: "https://github.com/miolabs/LuxerEngine.git", from: "1.0.0"),
```

Then choose the product that fits your needs:

```swift
// Core-only (head-less)
.product(name: "LuxerEngine", package: "LuxerEngine-Core"),

// Core + Metal (umbrella – easiest)
.product(name: "LuxerEngine", package: "LuxerEngine"),
```

---

## 3 · Quick-Start

### 3.1 Core + Metal

```swift
import LuxerEngine        // umbrella
import LuxerMetal         // Metal helpers

MetalRenderEngine.register()          // 1️⃣ register backend
LuxerEngine.initialize(               // boot engine
    configuration: .init(renderAPI: .metal, targetFPS: 60)
)
```

### 3.2 Head-less Mode

```swift
import LuxerEngine        // core-only target

LuxerEngine.initialize(
    configuration: .init(renderAPI: .none)   // no GPU needed
)
```

### 3.3 Render in an MTKView

```swift
let mtkView = MTKView(frame: view.bounds,
                      device: MTLCreateSystemDefaultDevice())
LuxerEngine.shared.render(in: MetalView(view: mtkView))
```

---

## 4 · Extending With New Back-Ends

1. Create SPM package `LuxerEngine-YourAPI`
2. Implement `RenderDevice`, encoder, view and a `RenderEngine` conforming to the core protocols
3. Register:

```swift
RenderEngineFactory.registerEngineCreator(for: .yourAPI) { cfg in
    YourAPIRenderEngine(cfg)
}
```

4. Depend on your package and select `renderAPI: .yourAPI`

_No changes to core code required._

---

## 5 · Key Concepts

| Concept | Description |
|---------|-------------|
| **RenderEngine protocol** | Abstracts GPU APIs (Metal, OpenGL, Vulkan, DirectX, or `none`) |
| **EngineSystem plugins** | Optional modules (LOD, physics, audio…) linked at compile time |
| **Component system** | Behaviour through composition – attach components to nodes |
| **Scenes** | Own nodes + systems; multiple scenes supported |
| **Head-less ready** | Core runs without any GPU framework |

---

## 6 · Roadmap

- [ ] OpenGL backend (`LuxerEngine-OpenGL`)
- [ ] Vulkan backend
- [ ] DirectX 12 backend
- [ ] Editor & asset pipeline

---

## 7 · License

MIT © 2025 Javier Segura Pérez & contributors
