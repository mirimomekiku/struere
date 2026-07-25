extern vec2 screen_size;
extern float edge_threshold;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 texel = vec2(1.0 / screen_size.x, 1.0 / screen_size.y);
    vec4 c = Texel(texture, texture_coords);

    vec4 c_left  = Texel(texture, texture_coords - vec2(texel.x, 0.0));
    vec4 c_right = Texel(texture, texture_coords + vec2(texel.x, 0.0));
    vec4 c_up    = Texel(texture, texture_coords - vec2(0.0, texel.y));
    vec4 c_down  = Texel(texture, texture_coords + vec2(0.0, texel.y));

    vec4 edge = abs(c_left - c_right) + abs(c_up - c_down);
    float edge_intensity = length(edge.rgb);

    if (edge_intensity > (1.0 - edge_threshold * 0.85)) {
        vec3 neon_edge = vec3(0.2, 0.95, 1.0) * edge_intensity * 1.6;
        return vec4(mix(c.rgb, neon_edge, 0.8), c.a) * color;
    }

    return c * color;
}
