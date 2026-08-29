class_name SkillBadge
extends RefCounted

## Pastille procédurale représentant une compétence : aucune texture, tout est
## dessiné au trait. La couleur encode la catégorie, les initiales la compétence.
## Le rendu reste net à n'importe quel zoom de caméra.
##
## Voir SkillBadgeRow pour afficher une série de pastilles sur une unité.

# Une couleur par catégorie de skill_cat_fr.json.
# Toutes sont assez sombres pour porter du texte blanc (contraste >= 4.5:1)
# et assez saturées pour ressortir sur la pelouse comme sur le parchemin.
const CATEGORY_COLORS := {
	"GENERAL": Color("4a5568"),    # ardoise
	"AGILITY": Color("0f7b64"),    # émeraude
	"STRENGTH": Color("9b2226"),   # carmin
	"PASSING": Color("1d4e89"),    # bleu profond
	"DEVIOUS": Color("5b21b6"),    # violet
	"MUTATIONS": Color("a8329a"),  # magenta
	"TRAITS": Color("8a5a00"),     # ambre
}
const FALLBACK_COLOR := Color("3f3f46")

const TEXT_COLOR := Color.WHITE
const OUTLINE_COLOR := Color(0.05, 0.05, 0.07, 0.9)

# Proportions relatives au rayon, pour que la pastille reste identique à toute taille.
const OUTLINE_RATIO := 0.12
const FONT_RATIO := 0.95
const TEXT_MAX_WIDTH_RATIO := 1.5
const MIN_FONT_SIZE := 6
# En dessous de ce rayon à l'écran, les initiales ne sont plus lisibles :
# on ne garde que la couleur, qui reste un signal valide.
const MIN_TEXT_RADIUS_PX := 11.0

# Mots ignorés dans le calcul des initiales : "Arracher le Ballon" donne "AB".
const STOP_WORDS := ["le", "la", "les", "de", "des", "du", "en", "et", "dans", "sur", "au", "aux", "un", "une"]
const PUNCTUATION := "()[]{}+-.,;:!?/\\\"'"


static func color_for_category(category: String) -> Color:
	return CATEGORY_COLORS.get(category, FALLBACK_COLOR)


static func color_for_skill(skill_uid: String) -> Color:
	var skill := BloodBowlManager.get_skill(skill_uid)
	if skill == null:
		return FALLBACK_COLOR
	return color_for_category(skill.category)


## Deux caractères identifiant la compétence, dérivés de son nom français.
static func initials_for_skill(skill_uid: String) -> String:
	var skill := BloodBowlManager.get_skill(skill_uid)
	if skill == null:
		return skill_uid.substr(0, 2).to_upper()
	return initials_from_name(skill.name)


## Texte d'infobulle : "Esquive — Agilité".
static func tooltip_for_skill(skill_uid: String) -> String:
	var skill := BloodBowlManager.get_skill(skill_uid)
	if skill == null:
		return skill_uid
	return "%s — %s" % [skill.name, BloodBowlManager.get_skill_category_label(skill.category)]


static func initials_from_name(skill_name: String) -> String:
	var words := _significant_words(skill_name)
	if words.is_empty():
		return skill_name.substr(0, 2).to_upper()

	# "Solitaire (3+)" donne "S3" plutôt que deux "SO" indistinguables.
	var qualifier := _numeric_qualifier(skill_name)
	if not qualifier.is_empty():
		return (words[0].substr(0, 1) + qualifier).to_upper()

	if words.size() >= 2:
		return (words[0].substr(0, 1) + words[1].substr(0, 1)).to_upper()
	return words[0].substr(0, 2).to_upper()


## Dessine une pastille centrée sur `center`. À appeler depuis le _draw() de `canvas`.
## `screen_scale` est le facteur d'échelle du canvas à l'écran (zoom caméra compris) :
## il sert uniquement à décider si les initiales sont encore lisibles.
static func draw_into(canvas: CanvasItem, center: Vector2, radius: float, color: Color,
		text: String, font: Font, screen_scale: float = 1.0) -> void:
	canvas.draw_circle(center, radius, OUTLINE_COLOR, true, -1.0, true)
	var inner_radius := radius - maxf(1.0, radius * OUTLINE_RATIO)
	canvas.draw_circle(center, inner_radius, color, true, -1.0, true)

	if text.is_empty() or font == null:
		return
	if radius * screen_scale < MIN_TEXT_RADIUS_PX:
		return

	var font_size := int(maxf(MIN_FONT_SIZE, radius * FONT_RATIO))
	var text_width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var max_width := radius * TEXT_MAX_WIDTH_RATIO
	if text_width > max_width:
		font_size = int(maxf(MIN_FONT_SIZE, font_size * max_width / text_width))
		text_width = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x

	# Centrage optique : on aligne sur la hauteur réelle des capitales, pas sur la ligne de base.
	var baseline := center.y + (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	canvas.draw_string(font, Vector2(center.x - text_width * 0.5, baseline), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, TEXT_COLOR)


static func _significant_words(skill_name: String) -> PackedStringArray:
	var words: PackedStringArray = []
	# L'apostrophe et le trait d'union séparent des mots : "Nerfs d'Acier" donne "NA".
	for raw in skill_name.replace("'", " ").replace("-", " ").split(" ", false):
		var word := _strip_punctuation(raw)
		if word.length() <= 1:
			continue
		if word.to_lower() in STOP_WORDS:
			continue
		words.append(word)
	return words


static func _strip_punctuation(word: String) -> String:
	var stripped := ""
	for i in word.length():
		var character := word[i]
		if character in PUNCTUATION or character.is_valid_int():
			continue
		stripped += character
	return stripped


## Premier chiffre entre parenthèses, pour distinguer les variantes numérotées.
static func _numeric_qualifier(skill_name: String) -> String:
	var opening := skill_name.find("(")
	if opening == -1:
		return ""
	for i in range(opening, skill_name.length()):
		if skill_name[i].is_valid_int():
			return skill_name[i]
	return ""
