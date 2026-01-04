shader_type spatial;
// depth_draw_always fixes many "missing background" issues in Godot 4
render_mode blend_mix, depth_draw_always, cull_disabled,diffuse_toon;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 0.1) = 0.02; // Small values work best for multi-sampling
uniform int iterations : hint_range(1, 20) = 8;
uniform vec4 bubble_color : source_color = vec4(0.7, 0.8, 1.0, 0.1);
uniform float fresnel_power : hint_range(0.1, 10.0) = 2.0;

void fragment() {
    // 1. Smooth Multi-Sample Blur
    // Instead of textureLod (which is blocky), we sample in a ring
    vec3 blurred_bg = vec3(0.0);
    float total_weight = 0.0;

    for (int i = 0; i < iterations; i++) {
        float angle = float(i) * (6.28318 / float(iterations));
        vec2 offset = vec2(cos(angle), sin(angle)) * blur_amount;
        blurred_bg += texture(screen_tex, SCREEN_UV + offset).rgb;
        total_weight += 1.0;
    }
    blurred_bg /= total_weight;

    // 2. Fresnel Effect (Glowing Edges)
    float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), fresnel_power);

    // 3. Final Composition
    vec3 final_color = mix(blurred_bg, bubble_color.rgb, bubble_color.a);
    ALBEDO = mix(final_color, bubble_color.rgb, fresnel);
    ALPHA = clamp(bubble_color.a + fresnel, 0.0, 1.0);

    // Physical properties
    ROUGHNESS = 0.05;
    SPECULAR = 0.5;
}
