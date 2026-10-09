{{flutter_js}}
{{flutter_build_config}}

// Some development browsers/GPUs cannot compile Flutter's WebGL shaders.
// Keep CanvasKit rendering available by falling back to CPU rasterization.
_flutter.loader.load({
  config: {
    canvasKitForceCpuOnly: true,
  },
});
