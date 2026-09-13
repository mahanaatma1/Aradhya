#version 460 core
#include <flutter/runtime_effect.glsl>
precision mediump float;

// Twinkling star field on a transparent ground (paint it over a sky).
uniform vec2 uResolution;
uniform float uTime;
uniform vec4 uColor;
uniform float uDensity;

out vec4 fragColor;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main() {
  vec2 px = FlutterFragCoord().xy;
  vec2 cell = floor(px / 18.0);
  vec2 f = fract(px / 18.0);
  float h = hash(cell);
  float on = step(1.0 - uDensity, h);
  vec2 sp = vec2(hash(cell + 1.7), hash(cell + 3.1));
  float d = distance(f, sp);
  float tw = 0.55 + 0.45 * sin(uTime * (2.0 + h * 5.0) + h * 40.0);
  float star = on * (1.0 - smoothstep(0.0, 0.08 + 0.06 * h, d)) * tw;
  fragColor = vec4(uColor.rgb * star, star * uColor.a);
}
