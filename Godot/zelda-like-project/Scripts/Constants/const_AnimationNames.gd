##[b][color=red]AnimationName[/color][/b] centralizes all animation name string constants.[br]
##Reference these instead of raw string literals to make renames compiler-detectable
##and eliminate silent typo bugs.
class_name AnimationName
extends RefCounted

const IDLE           : String = "Idle"
const EXHAUSTED_IDLE : String = "ExhaustedIdle"
const WALK           : String = "Walk"
const EXHAUSTED_WALK : String = "ExhaustedWalk"
const RUN            : String = "Run"
const GRAB           : String = "Grab"
const LIFT           : String = "Lift"
const CHEST_OPEN     : String = "ChestOpen"
const ITEM_GET       : String = "ItemGet"
