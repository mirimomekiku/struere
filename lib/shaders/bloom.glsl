extern float bloom_strength;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 tex = Texel(texture, texture_coords);
    vec3 base_col = tex.rgb;

    vec3 bloom = vec3(0.0);
    float off = 0.003;
    bloom += Texel(texture, texture_coords + vec2(off, 0.0)).rgb;
    bloom += Texel(texture, texture_coords - vec2(off, 0.0)).rgb;
    bloom += Texel(texture, texture_coords + vec2(0.0, off)).rgb;
    bloom += Texel(texture, texture_coords - vec2(0.0, off)).rgb;
    bloom *= (0.25 * bloom_strength);

    vec3 final_color = base_col + bloom;
    return vec4(final_color, tex.a) * color;
}
