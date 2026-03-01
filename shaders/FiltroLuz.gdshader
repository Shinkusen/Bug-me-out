shader_type canvas_item;

uniform vec2 player_position;
uniform float light_radius : hint_range(0.0, 1.0) = 0.4;
uniform float light_softness : hint_range(0.0, 1.0) = 0.4;

void fragment() {
    float dist = distance(SCREEN_UV, player_position);
    
    // Smoothstep cria uma transição suave entre o raio interno e o externo
    // Se light_softness for pequeno, a borda é dura. Se for grande, o degradê é longo.
    float mask = smoothstep(light_radius, light_radius + light_softness, dist);
    
    COLOR = vec4(0.0, 0.0, 0.0, mask);
}