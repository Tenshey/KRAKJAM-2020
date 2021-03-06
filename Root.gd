extends TileMap


export var next_level = "LVL3"

var doors_and_keys = { }

func _ready():
	get_parent().get_node("Player").position = $StartPoint.position
	
	for child in get_children(): 
		if "Key" in child.get_groups():
			if not doors_and_keys.has( child.key_id ): doors_and_keys[ child.key_id ] = {}
			if not doors_and_keys[ child.key_id ].has( "keys" ) : doors_and_keys[ child.key_id][ "keys" ] = []
			doors_and_keys[ child.key_id][ "keys" ].append( child )
			doors_and_keys[child.key_id][ "is_open"] = false
		if "Door" in child.get_groups():
			if not doors_and_keys.has( child.door_id ): doors_and_keys[ child.door_id ] = {}
			if not doors_and_keys[ child.door_id ].has( "door" ) : doors_and_keys[ child.door_id][ "door" ] = []
			doors_and_keys[ child.door_id][ "door" ].append( child )
			doors_and_keys[child.door_id][ "is_open"] = false

func unlock_doors( key_id ):
	if doors_and_keys[key_id][ "is_open"] : return
	doors_and_keys[key_id][ "is_open"] = true
	for door in doors_and_keys[ key_id ]["door"]:
		door.get_node("AnimationPlayer").play("Open")

func _on_Area2D_body_entered(body):
	if "player" in body.get_groups():
		call_deferred( "queue_free")
		get_parent().load_new_world( next_level, $StartPoint.position )

func _input(event):
	if event.is_action_pressed("ui_accept"):
		get_parent().load_new_world( next_level, $StartPoint.position )
		call_deferred( "queue_free")
	if event.is_action_pressed("ui_page_down"):
		get_parent().get_node("Player").increase_HP( 2 )

