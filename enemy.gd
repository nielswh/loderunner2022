extends KinematicBody2D

enum TILE { SKY = -1, FLOOR, FLOOR_SOLID, HOLE_DMG1, HOLE_DMG2, LADDER, RAILS, HOLE }
enum DIRECTION { IDLE = 0, LEFT, RIGHT, UP, DOWN }
# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var player : KinematicBody2D = null
var moveEnemy = false
var isOnLadder: bool = false
var isOnRails: bool = false
var isFalling: bool = false
var isInHole: bool = false
var currentDirection: int = DIRECTION.IDLE
var speed: int = 300
var vel : Vector2 = Vector2()
var tile: int = -1
var changeXDirAt: int = -1
var changeYDirAt: int = -1

const SIZE: int = 64
const HALF_SIZE: int = SIZE / 2
const QTR_SIZE: int = 14

onready var tilemap: TileMap = get_parent().get_node("TileMap")
onready var sprite: Sprite = get_node("Sprite")

# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_parent().get_node("Player")
	
	if not player:
		print("no player found")

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


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	vel.x = 0
	vel.y = 0
	
	if isFalling == true:
		getTileUpDown(false)
		vel.y += speed
	else:
		
		if not moveEnemy:
			return
		
		if currentDirection == DIRECTION.LEFT:
			$AnimationPlayer.play("LeftDirection")
			vel.x -= speed
			getTileLeftRight(true)
		elif currentDirection == DIRECTION.RIGHT:
			$AnimationPlayer.play("LeftDirection")
			vel.x += speed
			getTileLeftRight(false)
		elif currentDirection == DIRECTION.UP:
			$AnimationPlayer.play("Ladder")
			vel.y -= speed
			getTileUpDown(true)
		elif currentDirection == DIRECTION.DOWN:
			$AnimationPlayer.play("Ladder")
			getTileUpDown(false)
			vel.y += speed
			
	var enemyX = int(self.position.x) / SIZE
	var enemyY = int(self.position.y) / SIZE
	var playerX = int(player.position.x) / SIZE
	var playerY = int(player.position.y) / SIZE
	
	if changeXDirAt != -1:
		
		if enemyX == changeXDirAt:
			
			if playerY >= enemyY:
				currentDirection = DIRECTION.DOWN
			else:
				currentDirection = DIRECTION.UP
			self.position.x = enemyX * SIZE
			changeXDirAt = -1
			
			return
			
	if changeYDirAt != -1:
		if enemyY == changeYDirAt:
#			self.position.y -= 45
			
			if playerX >= enemyX:
				currentDirection = DIRECTION.RIGHT
			else:
				currentDirection = DIRECTION.LEFT
				
			changeYDirAt = -1
			return
			
	vel = move_and_slide(vel, Vector2.UP)
	
func checkTileLeftRight(x, y, isPlayerAbove):
	var currentTile = tilemap.get_cell(x, y)
	
	if currentTile == TILE.LADDER && isPlayerAbove:
		return x
		
	if currentTile != TILE.SKY: # We have something in the way
		return -1
		
	var currentTileBelow = tilemap.get_cell(x, y + 1)
	if currentTileBelow == TILE.SKY: # We have something in the way
		return -1
		
	if currentTileBelow == TILE.LADDER && not isPlayerAbove:
		return x
		
	return 99
		

func checkForLadderToLeft(enemyX, enemyY, isPlayerAbove):
	var xDir = -1
	
	for i in range(enemyX-1, 0, -1):
		xDir = checkTileLeftRight(i, enemyY, isPlayerAbove)
		if xDir != 99:
			currentDirection = DIRECTION.LEFT
			break
			
	if xDir == 99:
		xDir = -1
		
	changeXDirAt = xDir
			
func checkForLadderToRight(enemyX, enemyY, isPlayerAbove):
	var xDir = -1
	
	for i in range(enemyX+1, 42):
		xDir = checkTileLeftRight(i, enemyY, isPlayerAbove)
		if xDir != 99:
			currentDirection = DIRECTION.RIGHT
			break
			
	if xDir == 99:
		xDir = -1
	
	changeXDirAt = xDir
	
func checkForTopOfLadder(enemyX, enemyY):
	var yDir = -1  
	
	for i in range(enemyY, 0, -1):
		var currentTile = tilemap.get_cell(enemyX, i)
		
		if currentTile == TILE.SKY || currentTile == TILE.RAILS:
			yDir = i
			break
			
	if yDir <= 0:
		yDir =0
		
	changeYDirAt = yDir
	
func checkForBottomOfLadder(enemyX, enemyY, playerY):
	var yDir = playerY  
	
	var lastCheck = playerY-1
	if lastCheck <= enemyY:
		lastCheck = 18
	
	for i in range(enemyY+1, lastCheck):
		var currentTile = tilemap.get_cell(enemyX, i)
		
		if currentTile == TILE.SKY || currentTile == TILE.HOLE:
			yDir = -1
			currentDirection = DIRECTION.DOWN
			isFalling = true
			break
			
		if currentTile == TILE.FLOOR || currentTile == TILE.FLOOR_SOLID:
			yDir = -1
			changeXDirAt = enemyX
			break
			
			
		if currentTile != TILE.LADDER:
			yDir = i
			break
			
	changeYDirAt = yDir

func _on_Timer_timeout():
	if not player || isFalling:
		return
		
	var playerY = int(player.position.y) / SIZE
	var enemyY = int(self.position.y) / SIZE
	var playerX = int(player.position.x) / SIZE
	var enemyX = int(self.position.x) / SIZE
	
	if playerY == enemyY:
		changeXDirAt = -1
		moveEnemy = true
		
		if playerX >= enemyX:
			currentDirection = DIRECTION.RIGHT
		else:
			currentDirection = DIRECTION.LEFT
	else:
		# if its above us then we need to look for a ladder to get up
		var isPlayerAbove = true
		if playerY > enemyY:
			isPlayerAbove = false
		
		if currentDirection <= 2: # Left and Right Check
			if playerX <= enemyX:
				checkForLadderToLeft(enemyX, enemyY, isPlayerAbove)
				if changeXDirAt == -1:
					checkForLadderToRight(enemyX+1, enemyY, isPlayerAbove)
			else:
				checkForLadderToRight(enemyX, enemyY, isPlayerAbove)
				if changeXDirAt == -1:
					checkForLadderToLeft(enemyX-1, enemyY, isPlayerAbove)
		else: # Up OR Down
			if currentDirection == DIRECTION.UP: # Play is above
				checkForTopOfLadder(enemyX, enemyY)
			else:
				checkForBottomOfLadder(enemyX, enemyY, playerY)	
		
		moveEnemy = true
