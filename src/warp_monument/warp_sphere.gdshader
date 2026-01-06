shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled, diffuse_toon;

// --- New Vertex Uniforms ---
uniform float wobble_strength : hint_range(0.0, 0.5) = 0.05;
uniform float wobble_speed : hint_range(0.0, 5.0) = 2.0;

// --- Existing Fragment Uniforms ---
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 0.1) = 0.02;
uniform int iterations : hint_range(1, 20) = 8;
uniform vec4 bubble_color : source_color = vec4(0.7, 0.8, 1.0, 0.1);
uniform float fresnel_power : hint_range(0.1, 10.0) = 2.0;

// 1. Vertex Modification (Wobble)
void vertex() {
    // Displaces vertices along their normals based on time and position
    float displacement = sin(TIME * wobble_speed + (VERTEX.x + VERTEX.y + VERTEX.z) * 2.0) * wobble_strength;
    VERTEX += NORMAL * displacement;
}

void fragment() {
    // 2. Smooth Multi-Sample Blur
    vec3 blurred_bg = vec3(0.0);
    float total_weight = 0.0;

    for (int i = 0; i < iterations; i++) {
        float angle = float(i) * (6.28318 / float(iterations));
        vec2 offset = vec2(cos(angle), sin(angle)) * blur_amount;
        blurred_bg += texture(screen_tex, SCREEN_UV + offset).rgb;
        total_weight += 1.0;
    }
    blurred_bg /= total_weight;

    // 3. Fresnel Effect
    float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), fresnel_power);

    // 4. Final Composition
    vec3 final_color = mix(blurred_bg, bubble_color.rgb, bubble_color.a);
    ALBEDO = mix(final_color, bubble_color.rgb, fresnel);
    ALPHA = clamp(bubble_color.a + fresnel, 0.0, 1.0);

    ROUGHNESS = 0.05;
    SPECULAR = 0.5;
}
