#version 460 core
#include <flutter/runtime_effect.glsl>
precision mediump float;

// Radial lamp glow with a gentle 1/f-ish flicker — the diya, a halo, a
// streak flame. Center and radius are normalised.
uniform vec2 uResolution;
uniform float uTime;
uniform vec4 uColor;
uniform float uCx;
uniform float uCy;
uniform float uRadius;
uniform float uFlicker;

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / uResolution;
  vec2 c = vec2(uCx, uCy);
  float aspect = uResolution.x / uResolution.y;
  vec2 d = (uv - c) * vec2(aspect, 1.0);
  float f = 1.0 + uFlicker * (0.5 * sin(uTime * 9.0) + 0.3 * sin(uTime * 23.0 + 1.3) + 0.2 * sin(uTime * 41.0));
  float r = uRadius * f;
  float dist = length(d);
  float core = 1.0 - smoothstep(0.0, r * 0.25, dist);
  float halo = 1.0 - smoothstep(r * 0.1, r, dist);
  float a = clamp(core * 0.9 + halo * halo * 0.6, 0.0, 1.0);
  fragColor = vec4(uColor.rgb * a, a * uColor.a);
}
