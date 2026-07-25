extern float time;
extern float noise_intensity;
extern float jitter_strength;

float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = texture_coords;

    if (jitter_strength > 0.0) {
        float j_val = (rand(vec2(floor(screen_coords.y / 4.0), floor(time * 30.0))) - 0.5) * 2.0;
        if (abs(j_val) > 0.65) {
            uv.x += j_val * (jitter_strength * 0.012);
        }
    }

    vec4 base_col = Texel(texture, uv);

    if (noise_intensity > 0.0) {
        float n = (rand(screen_coords + vec2(time * 100.0, time * 50.0)) - 0.5) * noise_intensity * 0.35;
        base_col.rgb += vec3(n);
    }

    return base_col * color;
}
