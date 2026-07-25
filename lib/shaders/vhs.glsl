extern float time;
extern float vhs_intensity;

float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = texture_coords;

    float line_y = fract(time * 0.3);
    float dist = abs(uv.y - line_y);
    if (dist < 0.035 * vhs_intensity) {
        float shift = (rand(vec2(time, uv.y)) - 0.5) * 0.04 * vhs_intensity;
        uv.x += shift;
    }

    float offset = 0.0035 * vhs_intensity;
    float r = Texel(texture, uv + vec2(offset, 0.0)).r;
    float g = Texel(texture, uv).g;
    float b = Texel(texture, uv - vec2(offset, 0.0)).b;
    float a = Texel(texture, uv).a;

    float tape_noise = rand(vec2(uv.y * 60.0, time * 20.0));
    if (tape_noise > (1.0 - 0.04 * vhs_intensity)) {
        r += 0.25; g += 0.25; b += 0.25;
    }

    return vec4(r, g, b, a) * color;
}
