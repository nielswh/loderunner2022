extends KinematicBody2D

enum TILE { SKY = -1, FLOOR, FLOOR_SOLID, HOLE_DMG1, HOLE_DMG2, LADDER, RAILS, HOLE }

var speed: int = 300
var vel : Vector2 = Vector2()
var isOnLadder : bool = false
var isOnRails: bool = false
var isFalling: bool = false
var isInHole: bool = false
var isGoingLeft: bool = false
var isGoingUp: bool = false
var isDigging: bool = false
var digTime: float = 0.25
var digCount: float = 0.00
var playerStartPos: Vector2 = Vector2()
var tile: int = -1
var isDead:bool = false
const SIZE: int = 64
const HALF_SIZE: int = SIZE / 2
const QTR_SIZE: int = 14


onready var sprite: Sprite = get_node("Sprite")
onready var tilemap= get_parent().get_node("TileMap")
onready var timer: Timer = get_node("Timer")

func digHole(isLeftDirection, digTileId):
	
	if isOnLadder || isOnRails: # Can't Dig when on a ladder or rails
		return
	
	var x = int(self.position.x) / SIZE
	var y = (int(self.position.y) / SIZE) + 1
	
	if isLeftDirection:
		x -= 1
	else:
		x += 1
		
	var digTile = tilemap.get_cell(x, y)
	
	if digTile != TILE.FLOOR && digTile != TILE.HOLE_DMG1 && digTile != TILE.HOLE_DMG2:
		return
		
	tilemap.set_cell(x, y,  digTileId) # Dig Hole.
	
	if (digTileId == TILE.SKY):
		tilemap.addCellToHoleList(x, y)

func getTileUpDown(isUp):
	
	var prevTile = tile
	var x = int(self.position.x) / SIZE
	var y = int(self.position.y) / SIZE
	
	if isFalling == true: # Make sure we did not collide with anything that has collisions on such as the floor or hole
		if is_on_floor():
			isFalling = false
			return
			
	if isOnRails == true && isUp == false: # Drop off the Rails!
		isFalling = true
		isOnRails = false
		return
	
	if not isUp:
		y += 1
	
	tile = tilemap.get_cell(x, y)
	
	if isFalling && tile == TILE.LADDER:
		isOnLadder = true
		isFalling = false
		
		if isGoingUp == false:
			isGoingUp = true # We don't want to adjust adjus this values again
			self.position.y = (y * SIZE) + 8
	
	if isInHole == true:
		isFalling = false
		return
	
	if tile == TILE.SKY: # SKY
		if isUp == false:
			isFalling = true
			isOnLadder = false
			isOnRails = false
		else:
			self.position.y = (y * SIZE) + 28
			isFalling = false
			isOnLadder = false
			isOnRails = false
	elif tile == TILE.LADDER: # LADDER
		if isOnLadder == false:  # Only adjust if the first time on the ladder
			self.position.x = (x * SIZE) + HALF_SIZE
				
		isFalling = false
		isOnLadder = true
		isOnRails = false
	elif tile == TILE.RAILS: # RAILING
		if (prevTile == TILE.SKY) && isFalling == true:  # Fell onto the railing
			self.position.y = (y * SIZE) + QTR_SIZE
		
		isOnRails = true
		isFalling = false
		
	elif tile == TILE.HOLE: #HOLE
		if prevTile == TILE.SkY && isFalling == true:
			self.position.y = (y * SIZE)  # Drop into the hole
			isInHole = true
	else:
		if isFalling:
			if !GLOBAL.get_node("sfx/sfx_fall").is_playing():
				GLOBAL.get_node("sfx/sfx_fall").play()
			
		self.position.y = (y * SIZE) - HALF_SIZE
		isFalling = false
		isOnLadder = false
		isOnRails = false
	
func getTileLeftRight(isLeft):
	var prevTile = tile
	
	var x = int(self.position.x) / SIZE
	var y = int(self.position.y) / SIZE
	
	tile = tilemap.get_cell(x, y)
	
	if tile == TILE.RAILS: # RAILS
		self.position.y = (y * SIZE) + QTR_SIZE
			
		isFalling = false
		isOnLadder= false
		isOnRails = true
		return
		
	if isOnLadder == false && isOnRails == false:
		y += 1
		
	tile = tilemap.get_cell(x, y)
	
	if tile == TILE.FLOOR:
		var adjustedY = (y * SIZE) - HALF_SIZE
	
		if float(adjustedY) != self.position.y:
			self.position.y = adjustedY
	
	if prevTile == TILE.LADDER && tile == TILE.SKY:
		if isLeft:
			self.position.x -= HALF_SIZE
		else:
			self.position.x += HALF_SIZE
		
		isFalling = true
		return
	
	if tile == TILE.SKY: # SKY
		if isInHole:
			return

		isFalling = true
		isOnLadder = false
		isOnRails = false
	else:
		isFalling = false
		
	if tile == TILE.LADDER: # LADDER
			
		isFalling = false
		isOnLadder = false
		isOnRails = false
		
	if tile == TILE.RAILS: # RAILS
		self.position.y = (y * SIZE)
			
		isFalling = false
		isOnLadder= false
		isOnRails = true
		
	if tile == TILE.HOLE: # HOLE	
		self.position.y = (y * SIZE)
		
		isInHole = true
		isFalling = true
		isOnLadder= false
		isOnRails = false

# Called when the node enters the scene tree for the first time.
func _ready():
	timer.wait_time = digTime
	playerStartPos = self.position
	GLOBAL.restart_scene()
	pass # Replace with function body.	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	vel.x = 0
	vel.y = 0
	
	for i in get_slide_count():
		var collision = get_slide_collision(i)
		if collision && collision.collider.name == 'Enemy' && not isDead:
			self.hide()
			isDead = true
			print("hit")
			GLOBAL.player_dead()
			yield(get_tree().create_timer(1), "timeout")
			
			GLOBAL.restart_scene()
			yield(get_tree().create_timer(0.60), "timeout")
			self.position = playerStartPos
			self.show()
			isDead = false
		
	if isFalling == true:
		getTileUpDown(false)
		vel.y += speed
	else:
		if isDigging == false:
			if Input.is_action_pressed("ui_right"):
				getTileLeftRight(false)
				isGoingLeft = false		
				vel.x += speed
				if isOnRails == true:
					$AnimationPlayer.play("Rails Right")
				elif isOnLadder:
					$AnimationPlayer.play("Ladder Right")
				else:
					$AnimationPlayer.play("RightDirection")
					if !GLOBAL.get_node("sfx/sfx_walk").is_playing():
						GLOBAL.get_node("sfx/sfx_walk").play()
			elif Input.is_action_pressed("ui_left"):
				getTileLeftRight(true)
				isGoingLeft = true
				vel.x -= speed
				if isOnRails == true:
					$AnimationPlayer.play("Rails Left")
				elif isOnLadder:
					$AnimationPlayer.play("Ladder Left")
					
				else:
					$AnimationPlayer.play("LeftDirection")
					if !GLOBAL.get_node("sfx/sfx_walk").is_playing():
						GLOBAL.get_node("sfx/sfx_walk").play()
			elif Input.is_action_pressed("ui_down"):
				if !GLOBAL.get_node("sfx/sfx_ladder").is_playing() && isOnLadder:
					GLOBAL.get_node("sfx/sfx_ladder").play()
				isGoingUp = false
				getTileUpDown(false)
				
				if tile == TILE.LADDER:
					self.position.y += speed * delta
					$AnimationPlayer.play("DownDirection")

			elif Input.is_action_pressed("ui_up"):
				if !GLOBAL.get_node("sfx/sfx_ladder").is_playing() && isOnLadder:
					GLOBAL.get_node("sfx/sfx_ladder").play()
				
				isGoingUp = true
				getTileUpDown(true)
				
				if tile == TILE.LADDER:
					self.position.y -= speed * delta
					$AnimationPlayer.play("UpDirection")
			else:
				if isOnRails:
					$AnimationPlayer.play("idle Rails")
				elif isOnLadder:
					$AnimationPlayer.play("idle Ladder")
				else:
					if isGoingLeft:
						$AnimationPlayer.play("idleLeft")
					else:
						$AnimationPlayer.play("idleRight")
		
		if Input.is_action_pressed("ui_dig"):
			startDigging()
		if Input.is_action_pressed("ui_left_button"):
			isGoingLeft = true
			startDigging()
		if Input.is_action_pressed("ui_right_button"):
			isGoingLeft = false
			startDigging()
		elif Input.is_action_just_released("ui_dig") || Input.is_action_just_released("ui_left_button") || Input.is_action_just_released("ui_right_button"):
			if isDigging == true:
				timer.stop()
				isDigging = false
				digHole(isGoingLeft, TILE.FLOOR)
		
	if isOnLadder == false:
		vel = move_and_slide(vel, Vector2.UP)


func startDigging():
	if isDigging == true:
		if (digCount >= 0.50):
			digHole(isGoingLeft, TILE.HOLE_DMG2)
		return
		
	digCount = 0
	isDigging = true
	digHole(isGoingLeft, TILE.HOLE_DMG1)
	timer.start()

func _on_Timer_timeout():
	if isDigging:
		digCount += digTime
		if digCount < 0.75: 
			return
			
		digHole(isGoingLeft, TILE.SKY)
		isDigging = false	
		timer.stop()


func _on_TileMap_onHoldReset():
	var x = int(self.position.x) / SIZE
	var y = int(self.position.y) / SIZE
	var playerOnTile = tilemap.get_cell(x, y)
	
	if (playerOnTile == TILE.FLOOR):
		print("PLAYER WAS CRUSHED!")
		self.position = playerStartPos

