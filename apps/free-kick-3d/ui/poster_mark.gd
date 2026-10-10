extends TextureRect

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture = preload("res://ui/brand/title-raster.png")
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	stretch_mode = TextureRect.STRETCH_SCALE
