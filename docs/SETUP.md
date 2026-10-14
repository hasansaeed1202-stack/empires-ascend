# Project setup

Empires Ascend is a Godot 4 GDScript 3D RTS targeting Windows and modest hardware.
The foundation uses the GL Compatibility renderer and only engine primitives.

## Open and run

1. Install a current Godot 4.x release and its Windows export templates.
2. Import this repository by selecting `project.godot` in Godot Project Manager.
3. Press F6/F5 or run `godot --path .` to launch the default scene.
4. Use WASD or arrow keys to pan, Q/E to rotate, the mouse wheel to zoom,
   middle-mouse drag to rotate, and screen edges to pan.

The camera is bounded to the placeholder map. The green plane is the Terrain
physics layer and the center cube is an orientation marker.

## Verification

Run the automated foundation smoke test:

```powershell
godot --headless --path . --scene res://tests/foundation_test.tscn
```

Run the resource economy regression test:

```powershell
godot --headless --path . --scene res://tests/resource_store_test.tscn
```

Run the project and inspect parser/runtime errors:

```powershell
godot --path . --editor
godot --path .
```

Export the Windows placeholder build after installing export templates:

```powershell
godot --headless --path . --export-release "Windows Desktop" export/EmpiresAscend.exe
```

The export directory is intentionally ignored. Do not commit generated builds.

## Performance measurement

The target is 60 FPS on a GTX 1060 3 GB, fourth-generation Intel Core i7, and
12 GB RAM. Measure on that profile with Godot's debugger/profiler; record the
release-build FPS, resolution, duration, scene, and hardware. The repository does
not claim the target is met until that measurement is performed.
