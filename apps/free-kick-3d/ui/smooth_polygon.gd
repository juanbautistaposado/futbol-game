extends RefCounted

# Compatibility has no MSAA 2D. Cache supersampled white masks instead of
# rasterizing hard triangle edges on every redraw. Colors remain draw-time tints.
const RASTER_SCALE := 4.0
const TEXTURE_SCALE := 2
const PADDING := 2.0

var _masks: Dictionary[String, Dictionary] = {}

# Call outside _draw() when the owning Control changes its shape dimensions.
# The next redraw recreates only the masks needed for the new geometry.
func clear() -> void:
	_masks.clear()

# Intended for a small set of static decorative shapes, not animated vertices.
# Keep the helper as a member of the drawing Control so its textures stay alive.
func draw(item: CanvasItem, points: PackedVector2Array, color: Color) -> void:
	if points.size() < 3 or color.a <= 0.0:
		return
	var coordinates := PackedStringArray()
	for point in points:
		coordinates.append("%.4f,%.4f" % [point.x, point.y])
	var key := " ".join(coordinates)
	if not _masks.has(key):
		var mask := _create_mask(points, key)
		if mask.is_empty():
			item.draw_colored_polygon(points, color)
			return
		_masks[key] = mask
	var entry: Dictionary = _masks[key]
	item.draw_texture_rect(entry["texture"], entry["rect"], false, color)

func _create_mask(points: PackedVector2Array, coordinates: String) -> Dictionary:
	var bounds := Rect2(points[0], Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	var origin := bounds.position.floor() - Vector2.ONE * PADDING
	var extent := (bounds.end.ceil() + Vector2.ONE * PADDING - origin).ceil()
	if extent.x <= 0.0 or extent.y <= 0.0:
		return {}
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="%.4f %.4f %d %d"><polygon fill="white" points="%s"/></svg>' % [int(extent.x), int(extent.y), origin.x, origin.y, int(extent.x), int(extent.y), coordinates]
	var image := Image.new()
	var error := image.load_svg_from_string(svg, RASTER_SCALE)
	if error != OK:
		push_warning("Could not rasterize smooth UI polygon: %s" % error_string(error))
		return {}
	# Keep the fourfold sample coverage but only a twofold texture footprint.
	image.resize(int(extent.x) * TEXTURE_SCALE, int(extent.y) * TEXTURE_SCALE, Image.INTERPOLATE_LANCZOS)
	image.fix_alpha_edges()
	image.generate_mipmaps()
	return {"texture": ImageTexture.create_from_image(image), "rect": Rect2(origin, extent)}
