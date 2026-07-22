// NTSC Composite Video Artifact Shader
extern float time;
extern float artifact_strength;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = texture_coords;

    // NTSC color fringe signal simulation
    vec4 c = Texel(texture, uv);

    float shift = sin(screen_coords.y * 3.14159 + time * 10.0) * 0.002 * artifact_strength;
    float r = Texel(texture, uv + vec2(shift, 0.0)).r;
    float g = c.g;
    float b = Texel(texture, uv - vec2(shift, 0.0)).b;

    // Cross-color composite noise
    float noise = sin(screen_coords.x * 0.5 + screen_coords.y * 0.5 + time * 20.0) * 0.03 * artifact_strength;

    vec3 composite = vec3(r, g, b) + vec3(noise);
    return vec4(composite, c.a) * color;
}
