##[b][color=red]InputComponent[/color][/b] handles all input for signal sending; this can be used for players as the [i]PlayerInputComponent[/i] or enemies as the [i]EnemyInputComponent[/i].[br]
##All of them send the move(Vector2, float) signal, among others.
class_name InputComponent
extends Component

#region SIGNALS
#region Move Signals
##Signal when the move input is given.[br]
##[b]move_input[/b]: The direction of the movement (left, right, up, or down).
##[b]move_strength[/b]: The pressure/strength of the movement (a float value between 0 and 1).
signal onMove(move_input : Vector2, move_strength : float)
#endregion
