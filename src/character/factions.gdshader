shader_type spatial;

// Color configurations mapped directly from your FactionStatic colors
instance uniform vec4 color_none : source_color = vec4(0.7, 0.7, 0.7, 1.0);
instance uniform vec4 color_red : source_color = vec4(0.8, 0.1, 0.1, 1.0);
instance uniform vec4 color_blue : source_color = vec4(0.1, 0.2, 0.8, 1.0);
instance uniform vec4 color_green : source_color = vec4(0.1, 0.6, 0.15, 1.0);
instance uniform vec4 color_yellow : source_color = vec4(0.9, 0.8, 0.1, 1.0);
instance uniform vec4 color_purple : source_color = vec4(0.5, 0.1, 0.7, 1.0);

// Vector2 parameters: x = cumulative cutoff height, y = raw positive value strength (0.0 to 1.0)
instance uniform vec2 band_none = vec2(0.0);
instance uniform vec2 band_red = vec2(0.0);
instance uniform vec2 band_blue = vec2(0.0);
instance uniform vec2 band_green = vec2(0.0);
instance uniform vec2 band_yellow = vec2(0.0);
instance uniform vec2 band_purple = vec2(0.0);

void fragment() {
    float height = UV.y; // 0.0 at top, 1.0 at bottom
    
    // ROTATION FIX: Shift the UV coordinate by 0.25 (90 degrees) 
    // fract() ensures the value loops perfectly between 0.0 and 1.0
    float wrap = fract(UV.x + 0.25);   
    
    // DEFAULT FIX: Set fallback to your static unaligned grey color
    vec3 background_color = color_none.rgb; 
    vec3 final_color = background_color;
    
    float lowest_valid_cutoff = 2.0;
    float active_band_strength = 0.0;

    // 1. Evaluate NONE band height block
    if (band_none.y > 0.0 && height <= band_none.x && band_none.x < lowest_valid_cutoff) {
        lowest_valid_cutoff = band_none.x;
        final_color = color_none.rgb;
        active_band_strength = band_none.y;
    }
    // 2. Evaluate RED band height block
    if (band_red.y > 0.0 && height <= band_red.x && band_red.x < lowest_valid_cutoff) {
        lowest_valid_cutoff = band_red.x;
        final_color = color_red.rgb;
        active_band_strength = band_red.y;
    }
    // 3. Evaluate BLUE band height block
    if (band_blue.y > 0.0 && height <= band_blue.x && band_blue.x < lowest_valid_cutoff) {
        lowest_valid_cutoff = band_blue.x;
        final_color = color_blue.rgb;
        active_band_strength = band_blue.y;
    }
    // 4. Evaluate GREEN band height block
    if (band_green.y > 0.0 && height <= band_green.x && band_green.x < lowest_valid_cutoff) {
        lowest_valid_cutoff = band_green.x;
        final_color = color_green.rgb;
        active_band_strength = band_green.y;
    }
    // 5. Evaluate YELLOW band height block
    if (band_yellow.y > 0.0 && height <= band_yellow.x && band_yellow.x < lowest_valid_cutoff) {
        lowest_valid_cutoff = band_yellow.x;
        final_color = color_yellow.rgb;
        active_band_strength = band_yellow.y;
    }
    // 6. Evaluate PURPLE band height block
    if (band_purple.y > 0.0 && height <= band_purple.x && band_purple.x < lowest_valid_cutoff) {
        lowest_valid_cutoff = band_purple.x;
        final_color = color_purple.rgb;
        active_band_strength = band_purple.y;
    }

    // Horizontal threshold check
    if (wrap > active_band_strength) {
        ALBEDO = background_color;
    } else {
        ALBEDO = final_color;
    }
}
