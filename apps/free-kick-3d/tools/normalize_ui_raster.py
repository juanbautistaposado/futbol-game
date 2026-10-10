"""Trim generated UI alpha deterministically; retain the original source.

Requires Pillow. Removes disconnected exterior alpha specks, keeps edge coverage,
and adds a 4px transparent gutter. Run after copying sources to source-assets/ui.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[3]
TARGET = ROOT / "apps/free-kick-3d/ui/brand"
for source, target in [("title-generated.png", "title-raster.png"),
                       ("play-generated.png", "play-raster.png"),
                       ("configure-generated.png", "configure-raster.png")]:
    image = Image.open(ROOT / "source-assets/ui" / source).convert("RGBA")
    # Generated solid interiors peak at 253–254. Restore full opacity without
    # thresholding the fractional coverage of the antialiased silhouette.
    alpha = image.getchannel("A").point(lambda a: min(255, round(a * 255 / 253)))
    connected = alpha.point(lambda a: 255 if a > 128 else 0)
    ImageDraw.floodfill(connected, (image.width // 2, image.height // 2), 128)
    connected = connected.point(lambda a: 255 if a == 128 else 0)
    coverage = connected.filter(ImageFilter.MaxFilter(5))
    alpha = Image.composite(alpha, Image.new("L", image.size, 0), coverage)
    image.putalpha(alpha)
    bounds = alpha.getbbox()
    if not bounds:
        raise RuntimeError(f"Missing connected artwork: {source}")
    cropped = image.crop(bounds)
    normalized = Image.new("RGBA", (cropped.width + 8, cropped.height + 8))
    normalized.paste(cropped, (4, 4))
    normalized.save(TARGET / target)
    print(target, normalized.size, "alpha", normalized.getchannel("A").getextrema())
