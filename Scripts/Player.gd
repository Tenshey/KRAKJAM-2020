extends KinematicBody2D

export var GRAVITY = 200
export var SPEED = 1000
export var SPEED_JUMP = 3000
var UP = Vector2(0,-1)

signal _animate

const WORLD_LIMIT = 3000;

var motion = Vector2(0,0)

var lives = 3

var GRAPLING_HOOK_ENABLED   = true #for test
var grapling_shooted        = false
var grapling_hooked         = false
var grapling_lenght         = 700
var grapling_lenght_current = 0
var grapling_speed          = 1500
var grapling_direction      = Vector2(0,0)

func _grapling_hook(delta):
	if not GRAPLING_HOOK_ENABLED: return
	if Input.is_mouse_button_pressed(BUTTON_RIGHT) and not (  grapling_shooted or  grapling_hooked) : 
		$Skills/GraplingHook/Line2D.visible = true
		$Skills/GraplingHook/Line2D/Hook.visible = true
		var target_point    = get_viewport().get_mouse_position()
		var origin_position = get_global_transform_with_canvas().origin
		grapling_direction  = (target_point  - origin_position).normalized()
		grapling_shooted    = true
	
	if grapling_shooted and not grapling_hooked:
		grapling_lenght_current = min( grapling_lenght_current + grapling_speed * delta, grapling_lenght )
		var point     = grapling_direction * grapling_lenght_current
		$Skills/GraplingHook.cast_to = point 
		$Skills/GraplingHook/Line2D.points[1] = point
		$Skills/GraplingHook/Line2D/Hook.position = point
		
		if grapling_lenght_current == grapling_lenght : 
			grapling_shooted        = false
			grapling_lenght_current = 0
			$Skills/GraplingHook.cast_to = Vector2(0,0)
			$Skills/GraplingHook/Line2D.visible = false

		if $Skills/GraplingHook.is_colliding() :
			print( "Hooked", $Skills/GraplingHook.get_collider() )
			$Skills/GraplingHook/Line2D/Hook.visible = false
			#if $Skills/GraplingHook.get_collider().is_class("TileMap"):return
			
			
			grapling_hooked = true
			
	if grapling_hooked: 
		#$Skills/GraplingHook/Line2D.visible = false
		motion = grapling_direction * 600
		grapling_lenght_current = max( grapling_lenght_current - 600 * delta, 0 )
		var point     = grapling_direction * grapling_lenght_current
		$Skills/GraplingHook.cast_to = point 
		$Skills/GraplingHook/Line2D.points[1] = point
		if test_move( get_transform(), motion * delta ): 
			grapling_hooked  = false
			grapling_lenght_current = 0
			grapling_shooted = false
			$Skills/GraplingHook/Line2D.visible = false
		if not test_move( get_transform(), motion * 600 * delta ): 
			grapling_hooked  = false
			grapling_lenght_current = 0
			grapling_shooted = false
			$Skills/GraplingHook/Line2D.visible = false
	


func _physics_process(delta):
	_gravity()
	_movement()
	_jump()
	_grapling_hook(delta)
	move_and_slide(motion, UP)


func _animate():
	emit_signal("_animate", motion)


func _jump():
	if Input.is_action_pressed("jump") and is_on_floor():
		motion.y -= SPEED_JUMP 

func _movement():

	if Input.is_action_pressed("left"):
		motion.x = -SPEED
	elif Input.is_action_pressed("right"):
		motion.x = SPEED
	else:
		motion.x = 0

func _gravity():
	if position.y > WORLD_LIMIT:
		_endgame()
	if is_on_floor():
		motion.y = 0 
	elif is_on_ceiling():
		motion.y = 100
	else:
		motion.y += GRAVITY
		
func _endgame():
	get_tree().change_scene("res://Scenes/EndGame.tscn")
	
	
func _hurt():
	position.y -= -1
	motion.y -= SPEED_JUMP 
	lives -= 1
	if lives < 0:
			_endgame()
