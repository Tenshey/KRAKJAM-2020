extends KinematicBody2D

export var GRAVITY = 200
export var SPEED = 1000
export var SPEED_JUMP = 3000
var UP = Vector2(0,-1)

signal _animate

const WORLD_LIMIT = 3000;

var motion = Vector2(0,0)


var max_health = 100
var current_health = 100
var score = 0

var GRAPLING_HOOK_ENABLED   = true #for test
var grapling_shooted        = false
var grapling_hooked         = false
var grapling_lenght         = 750
var grapling_lenght_current = 0
var grapling_speed          = 1500
var grapling_direction      = Vector2(0,0)
var grapling_hit_point      = Vector2(0,0)
var grampling_cd_timer      = 0
var grampling_cd            = 1.5

var WALL_HOLDER_ENABLED     = true
var wall_holding            = false


func _ready():
	var tilemap_rect = get_parent().get_node("TileMap").get_used_rect()
	var tilemap_cell_size = get_parent().get_node("TileMap").cell_size
	
	$Camera2D.limit_left = (tilemap_rect.position.x  + 3) * tilemap_cell_size.x
	$Camera2D.limit_right = tilemap_rect.end.x * tilemap_cell_size.x
	$Camera2D.limit_top = tilemap_rect.position.y * tilemap_cell_size.y
	$Camera2D.limit_bottom = tilemap_rect.end.y * tilemap_cell_size.y
	
	current_health = max_health
	

func OnHit(damage):
	current_health -= damage
	healthBar.get_node("healthBar").value  = int((float (current_health) / max_health) * 100)

	

func activate_GramplingHook():
	
	if Input.is_mouse_button_pressed(BUTTON_RIGHT) and not ( grapling_shooted or  grapling_hooked) :
		$Skills/GraplingHook/Line2D.visible      = true
		$Skills/GraplingHook/Line2D/Hook.visible = true
		var target_point    = get_viewport().get_mouse_position()
		var origin_position = get_global_transform_with_canvas().origin
		grapling_direction  = (target_point  - origin_position).normalized()
		grapling_shooted    = true

func process_targeting_GramplingHook(delta):
	if grapling_shooted and not grapling_hooked:
		grapling_lenght_current = min( grapling_lenght_current + grapling_speed * delta, grapling_lenght )
		var point     = grapling_direction * grapling_lenght_current
		$Skills/GraplingHook.cast_to              = point 
		$Skills/GraplingHook/Line2D.points[1]     = point
		$Skills/GraplingHook/Line2D/Hook.position = point
		
		if grapling_lenght_current == grapling_lenght : 
			grapling_shooted        = false
			grapling_lenght_current = 0
			$Skills/GraplingHook.cast_to = Vector2(0,0)
			$Skills/GraplingHook/Line2D.visible = false

		if $Skills/GraplingHook.is_colliding() :
			$Skills/GraplingHook/Line2D/Hook.visible = false
			grapling_hit_point =  $Skills/GraplingHook.get_collision_point()
			grapling_hooked = true

func process_pull_GramplingHook(delta):
	if grapling_hooked: 
		motion = grapling_direction * SPEED
		grapling_lenght_current = max( grapling_lenght_current - SPEED * delta, 0 )
		var point     = grapling_direction * grapling_lenght_current
		$Skills/GraplingHook.cast_to = point 
		$Skills/GraplingHook/Line2D.points[1] = point
		
		var hit_the_wall     = test_move( get_transform(), motion * delta )
		var going_into_space = not test_move( get_transform(), motion * SPEED  * delta )
		
		if hit_the_wall or going_into_space:
			grapling_hooked  = false
			grapling_lenght_current = 0
			grapling_shooted = false
			$Skills/GraplingHook/Line2D.visible = false
			grampling_cd_timer = grampling_cd

func _grapling_hook(delta):
	if not GRAPLING_HOOK_ENABLED: return
	grampling_cd_timer -= delta
	
	if grampling_cd_timer > 0 : return
	
	activate_GramplingHook()
	process_targeting_GramplingHook(delta)
	process_pull_GramplingHook(delta)

func _physics_process(delta):
	_gravity()
	_movement()
	_jump()
	_grapling_hook(delta)
	_wall_holder(delta)
	move_and_slide(motion, UP)


func _animate():
	emit_signal("_animate", motion)

func _wall_holder(delta):
	if not WALL_HOLDER_ENABLED: return
	
	if Input.is_action_just_pressed("wall_hold"): wall_holding = true
	
	if Input.is_action_pressed("wall_hold"):
		wall_holding = true
		var distance = 100
		var close_wall = test_move( get_transform(), Vector2( -distance, 0 ) * delta ) or test_move( get_transform(), Vector2( distance, 0 ) * delta )
		if not close_wall : wall_holding = false
	else: wall_holding = false
	pass

func _jump():
	
	if Input.is_action_pressed("ui_up") and wall_holding:
		motion.y -= SPEED_JUMP
	
	if Input.is_action_pressed("ui_up") and is_on_floor():
		motion.y -= SPEED_JUMP 

func _movement():
	if wall_holding: return

	if Input.is_action_pressed("ui_left"):
		play_anim_if_not_played("MoveLeft")
		motion.x = -SPEED
	elif Input.is_action_pressed("ui_right"):
		play_anim_if_not_played("MoveRight")
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
		motion.y += GRAVITY/2 if grapling_shooted else  GRAVITY 
		if wall_holding : motion.y = 80

func _endgame():
	get_tree().change_scene("res://Scenes/EndGame.tscn")

func add_to_score(amount):
	score += amount

func play_anim_if_not_played(anim_name):
	if $AnimationPlayer.current_animation == anim_name : return
	$AnimationPlayer.play(anim_name)

func heal_cost( premium ):
	match( premium ):
		"G" : GRAPLING_HOOK_ENABLED = true

func _hurt():
	position.y -= -1
	motion.y -= SPEED_JUMP 
	OnHit(20)
	if current_health < 0:
		$"/root/healthBar".get_node("healthBar").visible = false
		_endgame()
