extends RefCounted
## Shared shot direction classification for opponent cues and feedback.

static func lane(x: float) -> int:
	return -1 if x < -0.85 else 1 if x > 0.85 else 0
