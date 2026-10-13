extends Node

## Shared foundation constants. Gameplay milestones should add data resources rather
## than growing this file into a general-purpose configuration store.

const RESOURCE_TYPES: Array[StringName] = [
	&"provisions",
	&"materials",
	&"craftsmanship",
	&"knowledge",
	&"influence",
	&"logistics",
]

const DEFAULT_RESOURCE_AMOUNT := 0
const MAX_RESOURCE_AMOUNT := 2_000
const TARGET_FRAMES_PER_SECOND := 60
const CAMERA_MIN_ZOOM := 8.0
const CAMERA_MAX_ZOOM := 32.0
