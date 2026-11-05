#include <flutter/runtime_effect.glsl>

uniform vec2 u_resolution;
uniform float u_time;

out vec4 fragColor;

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
        u.y
    );
}

void main() {
    vec2 uv = FlutterFragCoord().xy / u_resolution.xy;
    vec2 p = (FlutterFragCoord().xy * 2.0 - u_resolution.xy) / min(u_resolution.x, u_resolution.y);

    float t = u_time * 0.45;

    // Dark obsidian base (#050508)
    vec3 col = vec3(0.0196, 0.0196, 0.0314);

    // Electric cyan (#00F2FE)
    vec3 cyan = vec3(0.0, 0.949, 0.996);
    // Deep blue (#0051FF)
    vec3 deepBlue = vec3(0.0, 0.318, 1.0);
    // Indigo / Violet accent
    vec3 indigo = vec3(0.38, 0.18, 0.85);

    // Ambient radial light beams
    vec2 cyanBeam = vec2(0.2, 0.25);
    float dCyan = length(uv - cyanBeam);
    col += cyan * (0.16 / (dCyan * 2.5 + 0.6));

    vec2 blueBeam = vec2(0.8, 0.75);
    float dBlue = length(uv - blueBeam);
    col += deepBlue * (0.22 / (dBlue * 2.5 + 0.6));

    // Undulating digital silk neon wave lines
    vec3 waveColor = vec3(0.0);

    for (float i = 1.0; i <= 4.0; i += 1.0) {
        float freq = 1.1 * i;
        float speed = t * (0.35 + 0.12 * i);
        float offset = i * 0.7;

        float n = noise(vec2(p.x * 0.75 + speed * 0.4, offset + speed * 0.25));
        float y = sin(p.x * freq + speed + n * 1.8) * (0.32 / i) + (0.14 * (i - 2.5));

        float dist = abs(p.y - y);
        float line = 0.012 / (dist + 0.022);
        float glow = 0.032 / (dist * dist * 3.5 + 0.16);

        vec3 c = mix(cyan, deepBlue, sin(p.x * 1.4 + offset + t) * 0.5 + 0.5);
        if (i > 2.0) {
            c = mix(c, indigo, 0.3);
        }

        waveColor += c * (line * 0.65 + glow * 0.35);
    }

    col += waveColor;

    // Vignette overlay
    float vignette = uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y);
    vignette = clamp(pow(16.0 * vignette, 0.32), 0.0, 1.0);
    col *= vignette;

    fragColor = vec4(col, 1.0);
}

