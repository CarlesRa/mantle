class_name HealthBar
extends TextureProgressBar

const TWEEN_DURATION: float = 0.15
const TEXTURE_HEIGHT: int = 32
## Measured from potion_full.png (32x32): rows 29-31 below the liquid body (bottom row y=28).
const LIQUID_BOTTOM_OFFSET: int = 3
## Measured from potion_full.png (32x32): liquid body spans rows y=12..28 (17 px).
const LIQUID_HEIGHT: int = 17

var _tween: Tween
var _initialized: bool = false


func set_health(current: int, max_health: int) -> void:
	min_value = 0.0
	max_value = float(TEXTURE_HEIGHT)
	var target_value: float = 0.0
	if current > 0 and max_health > 0:
		target_value = float(LIQUID_BOTTOM_OFFSET) + (float(current) / float(max_health)) * float(LIQUID_HEIGHT)
	if not _initialized:
		value = target_value
		_initialized = true
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "value", target_value, TWEEN_DURATION)
