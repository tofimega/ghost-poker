@tool
class_name HandCont
extends Container


@export_range(0,1) var max_size: float = 1:
	set(s):
		max_size=s #TODO: implement this
		queue_sort()

@export_range(0,1) var max_spacing: float = 1:
	set(s):
		max_spacing=s
		queue_sort()
		
@export_range(0, 90) var max_rotation_deg: float = 30:
	set(s):
		max_rotation_deg=s
		queue_sort()
		
@export_range(0, 1) var begin_offset: float = 0:
	set(s):
		begin_offset=s
		queue_sort()

@export var child_positioning: ChildPositioning = ChildPositioning.CENTER:
	set(s):
		child_positioning=s
		queue_sort()

@export var child_pivot_offset: Vector2 = Vector2(0.5,0.5):
	set(s):
		child_pivot_offset=s
		queue_sort()


var ell_center: Vector2:
	get: 
		return Vector2((get_begin().x+get_end().x)/2, get_end().y)

var p1: Vector2
var p2: Vector2
var p3: Vector2
var curve: Curve2D

var children: Array

enum ChildPositioning{LEFT, CENTER, RIGHT}

func _ready() -> void:
	resized.connect(queue_sort)
	queue_sort()

func _draw() -> void:
	if !curve: return
	draw_polyline(curve.get_baked_points(), Color.BLUE_VIOLET, 2.0)

#TODO: adjust rotation
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SORT_CHILDREN:
			children = get_children().filter(func(c: Node): return c is Control)
			p1=Vector2(0, size.y)
			p2=Vector2(size.x/2, 0)
			p3=size
			curve=Curve2D.new()
			curve.add_point(p1,)
			curve.add_point(p2,Vector2(-p2.x-p1.x, 0))
			curve.add_point(p3,Vector2(0,p2.y-p3.y))
			curve.bake_interval=1

			
			if children.size()==1:
				match child_positioning:
					ChildPositioning.LEFT:
						var t: float = begin_offset
						children[0].pivot_offset=children[0].size*child_pivot_offset
						var transform: Transform2D = curve.sample_baked_with_rotation(remap(t,0,1,0,curve.get_baked_length()))
						children[0].position=transform.origin-children[0].size/2
						children[0].rotation=-transform.x.angle_to(Vector2.RIGHT) if begin_offset>0 else -PI/2
					ChildPositioning.CENTER:
						var t: float = 0.5
						children[0].pivot_offset=children[0].size*child_pivot_offset
						var transform: Transform2D = curve.sample_baked_with_rotation(remap(t,0,1,0,curve.get_baked_length()))
						children[0].position=transform.origin-children[0].size/2
						children[0].rotation=-transform.x.angle_to(Vector2.RIGHT) if t>0 else -PI/2
					ChildPositioning.RIGHT:
						var t: float = begin_offset
						children[0].pivot_offset=children[0].size*child_pivot_offset
						var transform: Transform2D = curve.sample_baked_with_rotation(remap(t,1,0,0,curve.get_baked_length()))
						children[0].position=transform.origin-children[0].size/2
						children[0].rotation=-transform.x.angle_to(Vector2.RIGHT) if t<1 else -PI/2
				return
			
			match child_positioning:
				ChildPositioning.LEFT:
					_sort_left()
				ChildPositioning.CENTER:
					_sort_center()
				ChildPositioning.RIGHT:
					_sort_right()
			
			normalize_rotation()


func normalize_rotation():
	if children.size()<1: return
	var _min_rot: float=children[0].rotation
	var _max_rot: float=children[-1].rotation
	
	for c in children:
		c.rotation=remap(c.rotation, _min_rot, _max_rot, max(deg_to_rad(-max_rotation_deg),_min_rot), min(deg_to_rad(max_rotation_deg), _max_rot))

func _sort(t: float, transform: Transform2D, lt1: bool)->void:
	var i: int = 1
	var spacing: float = min(1.0/(children.size()-1), max_spacing)
	var begin: int=1 if lt1 else 0
	var end: int=(begin+1) % 2
	while i < children.size():
		var _t: float=t+spacing
		if _t-t>max_spacing: _t=t+max_spacing
		
		children[i].pivot_offset=children[i].size*child_pivot_offset
		transform = curve.sample_baked_with_rotation(remap(_t,begin,end,0,curve.get_baked_length()))
		children[i].position=transform.origin-children[i].size/2
		children[i].rotation=-transform.x.angle_to(Vector2.RIGHT) if (_t>0 and !lt1) or (_t<1 and lt1) else -PI/2
		t=_t
		i+=1


func _sort_left()->void:
	if children.size()==0: return
	
	var t: float = begin_offset
	children[0].pivot_offset=children[0].size*child_pivot_offset
	var transform: Transform2D = curve.sample_baked_with_rotation(remap(t,0,1,0,curve.get_baked_length()))
	children[0].position=transform.origin-children[0].size/2
	children[0].rotation=-transform.x.angle_to(Vector2.RIGHT) if t>0 else -PI/2
	_sort(t, transform, false)


func _sort_center()->void:
	if children.size()==0: return
	var spacing: float = min(1.0/(children.size()-1), max_spacing)
	
	var t: float = 0.5-(spacing/2*(children.size()-1))
	children[0].pivot_offset=children[0].size*child_pivot_offset
	var transform: Transform2D = curve.sample_baked_with_rotation(remap(t,0,1,0,curve.get_baked_length()))
	children[0].position=transform.origin-children[0].size/2
	children[0].rotation=-transform.x.angle_to(Vector2.RIGHT) if t>0 else -PI/2
	
	_sort(t, transform, false)


func _sort_right()->void:
	if children.size()==0: return

	var t: float = begin_offset
	children[0].pivot_offset=children[0].size*child_pivot_offset
	var transform: Transform2D = curve.sample_baked_with_rotation(remap(t,1,0,0,curve.get_baked_length()))
	children[0].position=transform.origin-children[0].size/2
	children[0].rotation=-transform.x.angle_to(Vector2.RIGHT) if t<1 else -PI/2
	
	_sort(t, transform, true)
