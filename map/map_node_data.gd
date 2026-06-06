class_name MapNodeData
extends Resource

enum NodeType {BATTLE_NORMAL, BATTLE_HARD, SHOP, REST, BOSS}

@export var type: NodeType = NodeType.BATTLE_NORMAL
@export var grid_position: Vector2i
@export var next_connections: Array[Vector2i] = []
@export var wave_data: Array[EnemyStat]= []
@export var shoppable: bool = true
@export var price: int = 15
