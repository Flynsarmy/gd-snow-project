extends Node3D

const CIRCLE_TEX := preload("uid://b6fwdwx4grnvb")


var snow_mask_tex: DrawableTexture2D
# How many vertices per meter?
var mesh_density: int = 4

@onready var player: CharacterBody3D = $"../Snowball"
@onready var mask_tex_visual: TextureRect = $"../CanvasLayer/DisplacementTex"
@onready var mesh: MeshInstance3D = $Plane
# Grab the xz extents from our terrain
@onready var world_extents : Rect2 = Rect2(
	mesh.get_aabb().position.x,
	mesh.get_aabb().position.z,
	mesh.get_aabb().size.x,
	mesh.get_aabb().size.z
)
@onready var half_world_extents := world_extents.size * .5

func _ready() -> void:
	snow_mask_tex = DrawableTexture2D.new()
	# Set our snow displacement texture to the size of the mesh
	@warning_ignore("narrowing_conversion")
	snow_mask_tex.setup(
		#
		world_extents.size.x * mesh_density,
		world_extents.size.y * mesh_density,
		DrawableTexture2D.DRAWABLE_FORMAT_RGBA8
	)

	# Make our DrawableTexture visible on the screen
	mask_tex_visual.texture = snow_mask_tex

	# Load the snow mask into our shader
	var mesh_mat : ShaderMaterial = mesh.get_surface_override_material(0)
	mesh_mat.set_shader_parameter("dynamic_snow_mask", snow_mask_tex)

func _physics_process(_delta: float) -> void:
	var half_player_size := Vector2(.5, .5)
	var player_pos := (Vector2(player.position.x, player.position.z) + half_world_extents - half_player_size) * mesh_density
	var brush_pos := player_pos.floor()
	var brush_rect := Rect2(brush_pos, Vector2.ONE * mesh_density)

	snow_mask_tex.blit_rect(brush_rect, CIRCLE_TEX, Color.BLACK)
