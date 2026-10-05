shader_type spatial;

render_mode blend_mix, depth_draw_alpha_prepass, cull_disabled;

uniform vec4 water_color : source_color = vec4(
    0.03,
    0.30,
    0.42,
    0.72
);

uniform vec4 shallow_color : source_color = vec4(
    0.10,
    0.55,
    0.62,
    0.65
);

uniform float wave_speed = 0.035;
uniform float wave_strength = 0.035;
uniform float wave_scale = 4.0;

uniform float transparency = 0.72;


void vertex()
{
    /*
     * Two inexpensive wave patterns.
     */
    float wave_a = sin(
        VERTEX.x * wave_scale +
        TIME * wave_speed
    );

    float wave_b = cos(
        VERTEX.z * wave_scale * 1.37 +
        TIME * wave_speed * 0.8
    );

    VERTEX.y += (
        wave_a +
        wave_b
    ) * wave_strength;
}


void fragment()
{
    /*
     * Mix slightly between two water colors using world-ish UVs.
     */
    float variation = (
        sin(UV.x * 25.0 + TIME * 0.3) +
        cos(UV.y * 31.0 + TIME * 0.2)
    ) * 0.5 + 0.5;

    vec3 color = mix(
        water_color.rgb,
        shallow_color.rgb,
        variation * 0.25
    );

    ALBEDO = color;

    METALLIC = 0.05;
    ROUGHNESS = 0.08;

    ALPHA = transparency;
}
