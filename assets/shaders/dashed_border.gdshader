// dashed_border.gdshader
shader_type canvas_item;

uniform vec2 rect_size = vec2(210.0, 210.0);
uniform float border_width = 3.0;
uniform float corner_radius = 10.0;
uniform vec4 border_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 bg_color : source_color = vec4(0.2, 0.2, 0.3, 1.0);

uniform float dash_length = 10.0;
uniform float gap_length = 5.0;
uniform float animation_speed = 50.0;

// Fonction correcte pour la distance à un rectangle arrondi
float sdf_rounded_box(vec2 pos, vec2 size, float radius) {
    vec2 d = abs(pos) - size + radius;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - radius;
}

void fragment() {
    // Position centrée
    vec2 pos = (UV - 0.5) * rect_size;
    
    // Distance au rectangle arrondi
    float dist = sdf_rounded_box(pos, rect_size * 0.5, corner_radius);
    
    // Calculer la position sur le périmètre pour les pointillés
    vec2 abs_pos = abs(pos);
    float perimeter = 0.0;
    
    // Calcul de la position le long du périmètre
    if (abs_pos.x > abs_pos.y) {
        // Côtés gauche/droit
        perimeter = abs_pos.y + (pos.x > 0.0 ? 0.0 : rect_size.x + rect_size.y);
    } else {
        // Côtés haut/bas
        perimeter = rect_size.y + abs_pos.x + (pos.y > 0.0 ? 0.0 : rect_size.x);
    }
    
    // Animation
    perimeter += TIME * animation_speed;
    
    // Pattern de pointillés
    float dash_pattern = dash_length + gap_length;
    float dash_progress = mod(perimeter, dash_pattern);
    float is_dash = step(dash_progress, dash_length);
    
    // Dessiner la bordure et le fond
    if (dist > 0.0) {
        // En dehors du rectangle
        COLOR = vec4(0.0);
    } else if (dist > -border_width) {
        // Dans la bordure
        COLOR = border_color * is_dash;
    } else {
        // À l'intérieur
        COLOR = bg_color;
    }
}