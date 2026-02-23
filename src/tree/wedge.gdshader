shader_type spatial;
// cull_disabled allows us to see the back-faces (the "inside") of the mesh
render_mode cull_disabled, depth_draw_opaque;

uniform vec4 bark_color : source_color = vec4(0.3, 0.2, 0.1, 1.0);
uniform vec4 inner_wood_color : source_color = vec4(0.8, 0.7, 0.4, 1.0);

uniform vec3 cut_position;    // Use global_position from your hit script
uniform vec3 cut_direction;   // Normalized direction of the swing
uniform float cut_size = 0.0; // Grows with each hit (e.g., 0.0 to 0.5)

void fragment() {
    // 1. Calculate World Space Position
    vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
    vec3 diff = world_pos - cut_position;
    
    // 2. Define the V-Shape Wedge
    float forward_dist = dot(diff, cut_direction);
    float side_dist = length(cross(diff, cut_direction));
    float vertical_dist = abs(diff.y);
    
    // This formula creates the notch shape
    float wedge_shape = vertical_dist + (side_dist * 0.5) - (forward_dist * 0.2);

    // 3. Logic: Are we inside the chopped area?
    if (wedge_shape < cut_size && forward_dist > -cut_size) {
        // If we see the FRONT of the mesh inside the notch, delete it
        if (FRONT_FACING) {
            discard;
        } else {
            // If we see the BACK (the inside of the tree), show wood color
            ALBEDO = inner_wood_color.rgb;
            // Force the normal to face "out" of the cut for better lighting
            NORMAL = -NORMAL; 
        }
    } else {
        // Normal outside of the tree
        ALBEDO = bark_color.rgb;
    }
}
