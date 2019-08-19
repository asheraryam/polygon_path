tool
extends Spatial

# --
# GM Path
# --
# Alternative to the built in Path node with the following features:
# + New gizmo for easier handling
# + Constrained to a 3D plane
# + New keyboard shortcuts to enable / disable handles mirrors, length and snap
# + Method to check if a projected point is inside the curve
# + Working solution to know if the curve was updated or not
#
# --
#
# --

class_name GM_Path

signal curve_updated

## -- 
## Exported variables
## --
export(float) var polygon_resolution : float = 1

## -- 
## Public variables
## --

export var curve : Curve3D
var polygon : PolygonPathFinder
var polygon_points : PoolVector2Array
var size : Vector3
var center : Vector3
var closed_curve : bool = false

## --
## Internal variables
## --

## --
## Public methods
## --

func is_point_inside(point : Vector3):
	if not polygon:
		_update_from_curve()
	return polygon.is_point_inside(_get_projected_coords(point))

func add_point(position):
	if not curve:
		curve = Curve3D.new()
	curve.add_point(position)
	var index = curve.get_point_count() - 1
	var angle = curve.get_point_tilt(index)
	var dir = Vector2(cos(angle), sin(angle))
	var dir_in = dir
	var dir_out = dir.rotated(PI)
	
	curve.set_point_in(index, Vector3(dir_in.x, 0.0, dir_in.y))
	curve.set_point_out(index, Vector3(dir_out.x, 0.0, dir_out.y))
	
	_update_from_curve()

func set_closed_curve(value):
	closed_curve = value
	if closed_curve:
		# Create a new point, duplicate the first point data
		pass
	_update_from_curve()

func set_point_position(index, pos):
	curve.set_point_position(index, pos)
	_update_from_curve()

func set_point_in(index, pos):
	curve.set_point_in(index, pos)
	_update_from_curve()

func set_point_out(index, pos):
	curve.set_point_out(index, pos)
	_update_from_curve()

func remove_closest_to(pos):
	pass

## --
## Internal methods
## --

func _ready():
	_update_from_curve()

func _get_projected_coords(coords : Vector3):
	return Vector2(coords.x, coords.z)

# Travel the whole path to update the polygon and bounds
func _update_from_curve():
	var _min = null
	var _max = null
	var connections = PoolIntArray()
	polygon_points = PoolVector2Array()
	
	if not curve:
		curve = Curve3D.new()
	
	var length = curve.get_baked_length()
	var steps = round(length / polygon_resolution)
	
	if steps == 0:
		return

	for i in range(steps):
		# Get a point on the curve
		var coords_3d = curve.interpolate_baked((i/(steps-2)) * length)
		var coords = _get_projected_coords(coords_3d)
		
		# Store polygon data
		polygon_points.append(coords)
		connections.append(i)
		if(i == steps - 1):
			connections.append(0)
		else:
			connections.append(i + 1)
		
		# Check for bounds
		if i == 0:
			_min = coords
			_max = coords
		else:
			if coords.x > _max.x:
				_max.x = coords.x
			if coords.x < _min.x:
				_min.x = coords.x
			if coords.y > _max.y:
				_max.y = coords.y
			if coords.y < _min.y:
				_min.y = coords.y
	
	if not polygon:
		polygon = PolygonPathFinder.new()
	polygon.setup(polygon_points, connections)
	size = Vector3(_max.x - _min.x, 0.0, _max.y - _min.y)
	center = Vector3((_min.x + _max.x) / 2, 0.0, (_min.y + _max.y) / 2)
	
	_on_curve_update()
	emit_signal("curve_updated")

func _on_curve_update():
	pass

