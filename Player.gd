extends KinematicBody2D

enum TILE { SKY = -1, FLOOR, FLOOR_SOLID, HOLE_DMG1, HOLE_DMG2, LADDER, RAILS, HOLE }

var speed: int = 800
var vel : Vector2 = Vector2()
var isOnLadder : bool = false
var isOnRails: bool = false
var isFalling: bool = false
var isInHole: bool = false
var isGoingLeft: bool = false
var isDigging: bool = false
var digTime: float = 0.25
var digCount: float = 0.00
var playerStartPos: Vector2 = Vector2()

const railwayHangDist: int = 64
const distanceAdjustment: int = 65 

var tile: int = -1

onready var sprite: Sprite = get_node("Sprite")
onready var tilemap= get_parent().get_node("TileMap")
onready var timer: Timer = get_node("Timer")

func digHole(isLeftDirection, digTileId):
	
	if isOnLadder || isOnRails: # Can't Dig when on a ladder or rails
		return
	
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
	
	var lenCheck = distanceAdjustment
	var prevTile = tile
	
	if isFalling == true: # Make sure we did not collide with anything that has collisions on such as the floor or hole
		if is_on_floor():
			isFalling = false
			return
			
	if isOnRails == true && isUp == false: # Drop off the Rails!
		isFalling = true
		isOnRails = false
		return
		
	if prevTile == TILE.LADDER && isOnLadder == true: # Ladder
		lenCheck = 4  # on the Ladder.  Dont look to see what is above or below. 
	
	var pos = self.position
	
	if isUp == true:
		pos.y -= lenCheck
	else:
		pos.y += lenCheck
		
	if isFalling == false:
		pos.y += 64
		
	var tileVector = tilemap.world_to_map(pos)
	tile = tilemap.get_cellv(tileVector)
	print(tile)
	
	if isInHole == true:
		isFalling = false
		return
	
	if tile == TILE.SKY: # SKY
		if isUp == false:
			isFalling = true
			isOnLadder = false
			isOnRails = false
	elif tile == TILE.LADDER: # LADDER
		if isOnLadder == false:  # Only adjust if the first time on the ladder
			var xDist = sprite.global_position.x - tilemap.map_to_world(tileVector).x
			if abs(xDist) > 1:  #Adjust the player to be in the right position on the railings.
				self.position.x -= (xDist - railwayHangDist /2)
				
		isFalling = false
		isOnLadder = true
		isOnRails = false
	elif tile == TILE.RAILS: # RAILING
		
		var yDist = tilemap.map_to_world(tileVector).y - sprite.global_position.y
		
		if (prevTile == TILE.SKY) && isFalling == true:  # Fell onto the railing
			self.position.y += yDist + (railwayHangDist * .18)
		
		isOnRails = true
		isFalling = false
		
	elif tile == TILE.HOLE: #HOLE
		if prevTile == TILE.SkY && isFalling == true:
			self.position.y += 126  # Drop into the hole
			isInHole = true
	else:
		isFalling = false
		isOnLadder = false
		isOnRails = false
	
func getTileLeftRight(isLeft):
	var prevTile = tile
	var pos = self.position	
	var tileVector = tilemap.world_to_map(pos)
	tile = tilemap.get_cellv(tileVector)
	
	if tile == TILE.RAILS: # RAILS
		var yDist = sprite.global_position.y - tilemap.map_to_world(tileVector).y
		if yDist != railwayHangDist:  #Adjust the player to be in the right position on the railings.
			self.position.y += (railwayHangDist * 0.20)- yDist
			
		isFalling = false
		isOnLadder= false
		isOnRails = true
		return
	
	if isOnLadder == false && isOnRails == false:
		pos.y += distanceAdjustment	
		
	tileVector = tilemap.world_to_map(pos)
	tile = tilemap.get_cellv(tileVector)
	
	if tile == TILE.SKY: # SKY
		if isInHole:
			return
		
		if prevTile == TILE.LADDER:
			if isLeft:
				self.position.x -= distanceAdjustment / 2
			else:
				self.position.x += distanceAdjustment / 2
			
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
		var yDist = sprite.global_position.y - tilemap.map_to_world(tileVector).y
		if yDist != railwayHangDist:   #Adjust the player to be in the right position on the railings.
			self.position.y += railwayHangDist - yDist
			
		isFalling = false
		isOnLadder= false
		isOnRails = true
		
	if tile == TILE.HOLE: # HOLE
		if isLeft:
			self.position.x -= railwayHangDist / 4
		else:
			self.position.x += railwayHangDist / 4
			
		self.position.y += railwayHangDist
		
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
		print('falling')
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
				print('down')
				getTileUpDown(false)
				
				if tile == TILE.LADDER:
					self.position.y += speed * delta
					$AnimationPlayer.play("DownDirection")

			elif Input.is_action_pressed("ui_up"):
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
					$AnimationPlayer.play("idle")
		
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
	print(digCount)
	
	if isDigging:
		digCount += digTime
		if digCount < 0.75: 
			return
			
		digHole(isGoingLeft, TILE.SKY)
		isDigging = false	
		timer.stop()


func _on_TileMap_onHoldReset():
	var pos = self.position
	pos.y += railwayHangDist / 2
	var tileVector = tilemap.world_to_map(pos)
	var playerOnTile = tilemap.get_cellv(tileVector)
	
	if (playerOnTile == TILE.FLOOR):
		print("PLAYER WAS CRUSHED!")
		self.position = playerStartPos

