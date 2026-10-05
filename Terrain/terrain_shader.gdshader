shader_type spatial;

render_mode
	cull_back,
	diffuse_burley,
	specular_schlick_ggx;


// =====================================================================
// WATER
// =====================================================================

uniform float water_level = 2.0;


// =====================================================================
// HEIGHT MATERIALS
// =====================================================================

uniform float sand_height = 10.0;
uniform float sand_blend = 2.5;

uniform float dirt_height = 14.0;
uniform float grass_height = 26.0;
uniform float rock_height = 34.0;

uniform float height_blend = 2.5;


// =====================================================================
// ROCK
// =====================================================================

uniform float rock_slope_threshold = 0.58;
uniform float rock_slope_blend = 0.18;


// =====================================================================
// TEXTURE SCALE
// =====================================================================

uniform float texture_scale = 14.0;


// =====================================================================
// TEXTURES
// =====================================================================

uniform sampler2D sand_texture : source_color;
uniform sampler2D dirt_texture : source_color;
uniform sampler2D grass_texture : source_color;
uniform sampler2D rock_texture : source_color;


// =====================================================================
// SHORELINE
// =====================================================================

uniform bool shoreline_enabled = true;

uniform float shoreline_foam_width = 4.0;

uniform float shoreline_foam_strength = 0.7;

uniform vec4 shoreline_foam_color : source_color =
	vec4(0.92, 0.98, 1.0, 1.0);

uniform float shoreline_foam_noise_strength = 0.25;

uniform float shoreline_foam_noise_scale = 0.08;


// =====================================================================
// VARYINGS
// =====================================================================

varying vec3 world_position;

varying vec3 world_normal;

varying float shoreline_mask;


// =====================================================================
// VERTEX
// =====================================================================

void vertex()
{
	world_position =
		(MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	world_normal =
		normalize(
			MODEL_NORMAL_MATRIX *
			NORMAL
		);

	// Vertex color R contains the shoreline mask.
	shoreline_mask = COLOR.r;
}


// =====================================================================
// TRIPLANAR ROCK
// =====================================================================

vec3 triplanar_sample(
	sampler2D texture_map,
	vec3 position,
	vec3 normal
)
{
	vec3 weights = abs(normal);


	weights = pow(
		weights,
		vec3(4.0)
	);


	weights /= max(
		weights.x +
		weights.y +
		weights.z,
		0.0001
	);


	vec3 x_projection = texture(
		texture_map,
		position.yz /
		texture_scale
	).rgb;


	vec3 y_projection = texture(
		texture_map,
		position.xz /
		texture_scale
	).rgb;


	vec3 z_projection = texture(
		texture_map,
		position.xy /
		texture_scale
	).rgb;


	return
		x_projection * weights.x +
		y_projection * weights.y +
		z_projection * weights.z;
}


// =====================================================================
// HEIGHT BAND
// =====================================================================

float height_band(
	float height,
	float lower,
	float upper,
	float blend
)
{
	float lower_edge = smoothstep(
		lower - blend,
		lower + blend,
		height
	);


	float upper_edge = smoothstep(
		upper - blend,
		upper + blend,
		height
	);


	return clamp(
		lower_edge -
		upper_edge,
		0.0,
		1.0
	);
}


// =====================================================================
// FRAGMENT
// =====================================================================

void fragment()
{
	float height = world_position.y;


	// =============================================================
	// SLOPE
	// =============================================================

	// 0 = completely flat
	// 1 = vertical cliff
	float slope =
		1.0 -
		clamp(
			world_normal.y,
			0.0,
			1.0
		);


	// =============================================================
	// HEIGHT MATERIAL WEIGHTS
	//
	// These are deliberately overlapping.
	// There should never be a height where every material is zero.
	// =============================================================

	float sand_weight =
		1.0 -
		smoothstep(
			sand_height - sand_blend,
			sand_height + sand_blend,
			height
		);


	float dirt_weight =
		smoothstep(
			sand_height - sand_blend,
			sand_height + sand_blend,
			height
		) *
		(
			1.0 -
			smoothstep(
				dirt_height - height_blend,
				dirt_height + height_blend,
				height
			)
		);


	float grass_weight =
		smoothstep(
			dirt_height - height_blend,
			dirt_height + height_blend,
			height
		) *
		(
			1.0 -
			smoothstep(
				rock_height - height_blend,
				rock_height + height_blend,
				height
			)
		);


	float rock_height_weight =
		smoothstep(
			rock_height - height_blend,
			rock_height + height_blend,
			height
		);


	// =============================================================
	// ROCK FROM SLOPE
	// =============================================================

	float rock_slope_weight =
		smoothstep(
			rock_slope_threshold -
			rock_slope_blend,

			rock_slope_threshold +
			rock_slope_blend,

			slope
		);


	// Rock can come from either:
	//
	// 1. being high enough
	// 2. being steep enough
	//
	float rock_weight =
		max(
			rock_height_weight,
			rock_slope_weight
		);


	// =============================================================
	// STEEP ROCK SHOULD REPLACE THE OTHER MATERIALS
	// =============================================================

	float non_rock =
		1.0 -
		rock_weight;


	sand_weight *= non_rock;
	dirt_weight *= non_rock;
	grass_weight *= non_rock;


	// =============================================================
	// NORMALIZE
	//
	// This is also protected against zero-weight situations.
	// =============================================================

	float total =
		sand_weight +
		dirt_weight +
		grass_weight +
		rock_weight;


	if (total < 0.0001)
	{
		// This should practically never happen now, but use
		// grass as a safe fallback instead of producing black.
		grass_weight = 1.0;
		total = 1.0;
	}


	sand_weight /= total;
	dirt_weight /= total;
	grass_weight /= total;
	rock_weight /= total;


	// =============================================================
	// SAND
	// =============================================================

	vec3 sand =
		texture(
			sand_texture,
			UV * texture_scale
		).rgb;


	// =============================================================
	// DIRT
	// =============================================================

	vec3 dirt =
		texture(
			dirt_texture,
			UV * texture_scale
		).rgb;


	// =============================================================
	// GRASS
	// =============================================================

	vec3 grass =
		texture(
			grass_texture,
			UV * texture_scale
		).rgb;


	// =============================================================
	// ROCK - TRIPLANAR
	// =============================================================

	vec3 rock =
		triplanar_sample(
			rock_texture,
			world_position,
			world_normal
		);


	// =============================================================
	// COMBINE MATERIALS
	// =============================================================

	vec3 terrain_color =
		sand * sand_weight +
		dirt * dirt_weight +
		grass * grass_weight +
		rock * rock_weight;


	// =============================================================
	// SHORELINE FOAM
	// =============================================================

	float foam = 0.0;


	if (shoreline_enabled)
	{
		foam = shoreline_mask;


		float noise_x =
			sin(
				world_position.x *
				shoreline_foam_noise_scale
			);


		float noise_z =
			cos(
				world_position.z *
				shoreline_foam_noise_scale *
				1.37
			);


		float foam_noise =
			noise_x *
			noise_z;


		foam_noise =
			foam_noise * 0.5 +
			0.5;


		foam = mix(
			foam,
			foam * foam_noise,
			shoreline_foam_noise_strength
		);


		foam *= shoreline_foam_strength;


		float water_distance =
			abs(
				height -
				water_level
			);


		float height_foam =
			1.0 -
			smoothstep(
				0.0,
				shoreline_foam_width,
				water_distance
			);


		foam *= height_foam;
	}


	// =============================================================
	// APPLY FOAM
	// =============================================================

	terrain_color = mix(
		terrain_color,
		shoreline_foam_color.rgb,
		clamp(
			foam,
			0.0,
			1.0
		)
	);


	// =============================================================
	// OUTPUT
	// =============================================================

	ALBEDO = terrain_color;


	ROUGHNESS = mix(
		0.85,
		0.65,
		rock_weight
	);
}
