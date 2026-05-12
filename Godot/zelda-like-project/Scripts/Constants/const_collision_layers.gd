## Named collision layer constants.
##
## These define the collision layers used throughout the project.
## Instead of using magic numbers like `1`, `2`, etc., refer to these constants.
class_name CollisionLayers

const GROUND = 1
const CHARACTER = 2
const INTERACTABLE = 2
const ENEMY = 4
const PROJECTILE = 8
const TRAP = 8
const WALL = 32
