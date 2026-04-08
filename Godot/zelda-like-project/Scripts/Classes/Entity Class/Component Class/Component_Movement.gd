##[b][color=red]MoveComponent[/color][/b] is the handler for all movement a Character entity can take, regardless of their type.[br]
class_name MoveComponent
extends Component

#region VARIABLES
#region Export Variables
@export_group("Movement Components")
@export_group("Movement Variables")
@export_subgroup("Values")
#endregion
#region Internal Variables
## The parent entity; resolved by walking up the scene tree to find the owning Character.
@onready var root : Character = _find_entity_parent() as Character
##The entity from which this move component receives its move signals; expects an InputComponent
@onready var input : InputComponent = root.input
##a reference to the CharacterBody2D node of a character
@onready var body : CharacterBody2D = root.body
##The direction of the entity's movement; this is received from the moveSignal.
var move_dir : Vector2
##The strength of the entity's movement; this is received from the moveSignal.
var move_str : float
#endregion
#endregion VARIABLES

#region FUNCTIONS

func _ready():
	#Read walk speed from stats as the default move speed.
	var stats = _get_entity_stats()
	root.move_speed = stats.walk_speed if stats else 50.0
	#connect signals
	input.on_move.connect(move)

func move(move_input, move_strength):
	move_dir = move_input
	move_str = move_strength
	# Yield to State_Dash / State_Backstep when they own physics.
	if root.is_dashing:
		return
	#Configures the state machine to prevent moving while the movement layer is frozen.
	if root.state_machine and root.state_machine.movement_layer \
	and not root.state_machine.movement_layer.is_active:
		body.velocity = Vector2.ZERO
		return
	#The move direction and rate of movement for the character; determined by their move input.
	#Pulls a reference to the character's main self for this function.
	body.velocity = move_dir * root.move_speed
	#Apply the movement as intended.
	body.move_and_slide()
	if debug_me:
		print(debug_name, ": is moving with a move_dir of ", move_dir, " and a move_str of ", move_str)

##For playing footstep sounds and adding effects, eventually.
func play_footstep():
	pass
	
#endregion FUNCTIONS
