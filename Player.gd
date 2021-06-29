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

onready var sprite: Sprite = get_node("Sprite")
onready var tilemap= get_parent().get_node("TileMap")
onready var timer: Timer = get_node("Timer")

func digHole(isLeftDirection, digTileId):
	
	if isOnLadder || isOnRails: # Can't Dig when on a ladder or rails
		return
	
	var distanceAdjustment: int = 40 
	var pos = self.position
	var adjustBy = 1
	var digAdjust = distanceAdjustment * 0.50
	
	if isLeftDirection:
		adjustBy = -1
	
	pos.y += distanceAdjustment
	pos.x += digAdjust * adjustBy
		
	var tileVector = tilemap.world_to_map(pos)
	var digTile = tilemap.get_cellv(tileVector)
	var xDist = 0
	
	if isLeftDirection == true:
		xDist = tilemap.map_to_world(tileVector).x - sprite.global_position.x
	else:
		xDist = sprite.global_position.x - tilemap.map_to_world(tileVector).x
	
	if (xDist < digAdjust):
		pos.x += digAdjust * adjustBy
		tileVector = tilemap.world_to_map(pos)
		digTile = tilemap.get_cellv(tileVector)
	
	if digTile != TILE.FLOOR && digTile != TILE.HOLE_DMG1 && digTile != TILE.HOLE_DMG2:
		return
		
	tilemap.set_cellv(tileVector, digTileId) # Dig Hole.
	
	if (digTileId == TILE.SKY):
		tilemap.addCellToHoleList(tileVector)

func getTileUpDown(isUp):
	
	var prevTile = tile
	var x = int(self.position.x) / 64
	var y = int(self.position.y) / 64
	
	if isFalling == true: # Make sure we did not collide with anything that has collisions on such as the floor or hole
		if is_on_floor():
			isFalling = false
			return
			
	if isOnRails == true && isUp == false: # Drop off the Rails!
		isFalling = true
		isOnRails = false
		return
	
	if isUp:
		y += 0
	else:
		y += 1
	
	tile = tilemap.get_cell(x, y)
	
	if isFalling && tile == TILE.LADDER:
		isOnLadder = true
		isFalling = false
		
		if isGoingUp == false:
			isGoingUp = true # We don't want to adjust adjus this values again
			var remainder = int(self.position.y) % 64
			self.position.y = int(self.position.y) + remainder + 6
	
	if isInHole == true:
		isFalling = false
		return
	
	if tile == TILE.SKY: # SKY
		if isUp == false:
			isFalling = true
			isOnLadder = false
			isOnRails = false
		else:
			self.position.y = (y * 64) + 28
			isFalling = false
			isOnLadder = false
			isOnRails = false
	elif tile == TILE.LADDER: # LADDER
		if isOnLadder == false:  # Only adjust if the first time on the ladder
			self.position.x = (x * 64) + 32
				
		isFalling = false
		isOnLadder = true
		isOnRails = false
	elif tile == TILE.RAILS: # RAILING
		if (prevTile == TILE.SKY) && isFalling == true:  # Fell onto the railing
			self.position.y = (y * 64) + 14
		
		isOnRails = true
		isFalling = false
		
	elif tile == TILE.HOLE: #HOLE
		if prevTile == TILE.SkY && isFalling == true:
			self.position.y = (y * 64)  # Drop into the hole
			isInHole = true
	else:
		self.position.y = (y * 64) - 32
		isFalling = false
		isOnLadder = false
		isOnRails = false
	
func getTileLeftRight(isLeft):
	var prevTile = tile
	
	var x = int(self.position.x) / 64
	var y = int(self.position.y) / 64
	
	tile = tilemap.get_cell(x, y)
	
	if tile == TILE.RAILS: # RAILS
		self.position.y = (y * 64) + 14
			
		isFalling = false
		isOnLadder= false
		isOnRails = true
		return
		
	if tile == TILE.FLOOR:
		var adjustedY = (y * 64) + 32
	
		if (float(adjustedY) != position.y):
			self.position.y = (y * 64) + 32
	
	if isOnLadder == false && isOnRails == false:
		y += 1
		
	tile = tilemap.get_cell(x, y)
	
	if prevTile == TILE.LADDER && tile == TILE.SKY:
		if isLeft:
			self.position.x -= 32
		else:
			self.position.x += 32
		
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
		self.position.y = (y * 64)
			
		isFalling = false
		isOnLadder= false
		isOnRails = true
		
	
		
	if tile == TILE.HOLE: # HOLE	
		self.position.y = (y * 64)
		
		isInHole = true
		isFalling = true
		isOnLadder= false
		isOnRails = false

# Called when the node enters the scene tree for the first time.
func _ready():
	timer.wait_time = digTime
	playerStartPos = self.position
	pass # Replace with function body.	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	vel.x = 0
	vel.y = 0
	
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
			elif Input.is_action_pressed("ui_down"):
				isGoingUp = false
				getTileUpDown(false)
				
				if tile == TILE.LADDER:
					self.position.y += speed * delta
					$AnimationPlayer.play("DownDirection")

			elif Input.is_action_pressed("ui_up"):
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
	var x = int(self.position.x) / 64
	var y = int(self.position.y) / 64
	var playerOnTile = tilemap.get_cell(x, y)
	
	if (playerOnTile == TILE.FLOOR):
		print("PLAYER WAS CRUSHED!")
		self.position = playerStartPos

