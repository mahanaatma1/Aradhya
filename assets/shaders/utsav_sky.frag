#version 460 core
#include <flutter/runtime_effect.glsl>
precision mediump float;

// Animated festival sky: three colour bands that drift and breathe, with a
// blue-noise dither so the gradient never bands on 8-bit panels.
uniform vec2 uResolution;
uniform float uTime;
uniform vec4 uC0;
uniform vec4 uC1;
uniform vec4 uC2;
uniform float uSpeed;

out vec4 fragColor;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uResolution;
  float t = uTime * uSpeed;
  float wave = 0.08 * sin(uv.x * 4.0 + t * 0.7) + 0.05 * sin(uv.x * 9.0 - t * 1.1);
  float y = clamp(uv.y + wave, 0.0, 1.0);
  vec3 col = y < 0.5
      ? mix(uC0.rgb, uC1.rgb, smoothstep(0.0, 0.5, y))
      : mix(uC1.rgb, uC2.rgb, smoothstep(0.5, 1.0, y));
  // soft radial glow near the horizon
  float glow = 1.0 - smoothstep(0.0, 0.9, distance(uv, vec2(0.5, 0.95)));
  col += uC1.rgb * glow * 0.18;
  col += (hash(FlutterFragCoord().xy) - 0.5) / 255.0;
  fragColor = vec4(col, 1.0);
}
