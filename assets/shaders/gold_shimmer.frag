#version 460 core
#include <flutter/runtime_effect.glsl>
precision mediump float;

// A specular band sweeping diagonally across the box. Paint it with
// BlendMode.plus or as a ShaderMask over gold text / borders.
uniform vec2 uResolution;
uniform float uTime;
uniform vec4 uColor;
uniform float uSpeed;
uniform float uWidth;

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / uResolution;
  float d = uv.x * 0.8 + uv.y * 0.6;
  float pos = fract(uTime * uSpeed) * 2.2 - 0.6;
  float band = 1.0 - smoothstep(0.0, uWidth, abs(d - pos));
  float shine = pow(band, 2.2);
  fragColor = vec4(uColor.rgb * shine, shine * uColor.a);
}
