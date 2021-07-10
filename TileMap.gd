extends TileMap

enum TILE { SKY = -1, FLOOR, FLOOR_SOLID, HOLE_DMG1, HOLE_DMG2, LADDER, RAILS, HOLE }

signal onHoldReset()

var secondsCount: float = 0
var holeReset: int = 4 # Number of seconds before a hole is filled in,
var holesList = []
var holesCreated: int = 0
onready var timer = self.get_parent().get_node("Timer")

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

func addCellToHoleList(x, y):
	holesList.append({"x": x, "y": y, "created": secondsCount})
	holesCreated += 1 
	

# Called when the node enters the scene tree for the first time.
func _ready():
	timer.set_wait_time(0.5)


func _on_Timer_timeout():
	secondsCount += 0.5

	var holesToReset = []
	
	if holesList.empty() == true:
		return
		
	var index: int = 0
	for hole in holesList:
		
		if secondsCount > hole["created"] + holeReset: 
			self.set_cell(hole["x"],  hole["y"], TILE.FLOOR)
			holesToReset.insert(0, index) # Make sure to add to front of array so we can remove from highest to lowest
			emit_signal("onHoldReset")
		elif secondsCount > hole["created"] + (holeReset - 0.5): # Start to fill in hwn their is 1 second left
			self.set_cell(hole["x"],  hole["y"], TILE.HOLE_DMG1)
		index += 1
	
	if holesToReset.empty() == false:	
		for hole in holesToReset:
			holesList.remove(hole)
