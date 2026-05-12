##[b]FUTURE WORK: Data-driven effect system via plugin pattern[/b]
##
##Currently, effects are hardcoded via EffectEnums and specific effect classes:
##  - resource_itemFunction_Effect_Enums.gd (defines action/target types)
##  - resource_itemFunction_Effect_Immediate.gd (instantaneous effects)
##  - resource_itemFunction_Effect_Ongoing.gd (duration-based effects)
##  - resource_itemFunction_Effect_Permanent.gd (permanent stat changes)
##
##[b]Problem:[/b]
##  - Adding new effect types (e.g., Stamina, Status Effects) requires modifying EffectEnums.gd
##  - Tight coupling between item definitions and effect handling
##  - Difficult to organize effect logic as complexity grows
##
##[b]Intended Design:[/b]
##  - Effects register themselves to an autoload registry by action/target type
##  - New effect plugins can be added without modifying EffectEnums.gd or core effect files
##  - Each effect type owns its own action/target constants and handler logic
##  - Registry pattern allows dynamic composition of effect behavior
##  - Example structure:
##    - EffectPlugin interface: contract for action_type, target_type, apply()
##    - EffectRegistry autoload: register(plugin), get_handler(action, target)
##    - Individual effect plugins: StaminaEffect, StunEffect, PoisonEffect, etc.
##
##[b]Migration Path:[/b]
##  1. Create EffectPlugin interface contract
##  2. Create EffectRegistry autoload
##  3. Move existing effect types into plugin implementations
##  4. Update ItemFunction to query registry instead of switch on enum
##  5. Deprecate EffectEnums.gd
##
##This is a large architectural change; do not begin until effect system complexity justifies it.
class_name EffectPlugin_FUTURE
extends Resource
