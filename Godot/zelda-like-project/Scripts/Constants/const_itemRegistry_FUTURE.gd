##[b]FUTURE WORK: Distributed ItemID registry via autoload pattern[/b]
##
##Currently, all item IDs are centralized in const_itemIDs.gd as a single enum.
##
##[b]Problem:[/b]
##  - Single file becomes a merge conflict hot spot as project grows
##  - All item data (IDs, names, descriptions, icons) tightly coupled
##  - Difficult to organize items by category (weapons, armor, consumables, etc.)
##  - Adding items requires updating central const file (not modular)
##
##[b]Intended Design:[/b]
##  - Items register themselves to an ItemRegistry autoload by category/tag
##  - Each item category (or content pack) owns its own ID namespace
##  - Example structure:
##    - ItemRegistry autoload: register(category, id, data), get_item(id), query_by_tag(tag)
##    - Weapons category: auto-registers weapon IDs
##    - Armor category: auto-registers armor IDs
##    - Consumables category: auto-registers consumable IDs
##  - ID collision detection prevents duplicates across categories
##  - Safe fallback to const_itemIDs.gd for lookups during migration
##
##[b]Benefits:[/b]
##  - Reduced merge conflicts (distributed registration)
##  - Items can register themselves on _ready() (modular)
##  - Easy to add new item types without central file changes
##  - Query by tag enables flexible inventory filtering
##  - Supports runtime item mods/DLC without recompile
##
##[b]Migration Path:[/b]
##  1. Create ItemRegistry autoload with registration API
##  2. Create ItemID interface/contract for what registerable items expose
##  3. Migrate category-by-category: weapons, armor, consumables, dungeon items, etc.
##  4. Update lookups to query registry first, fall back to const_itemIDs.gd
##  5. Once all categories migrated, deprecate const_itemIDs.gd
##
##This is a large architectural change; do not begin until item count or merge conflict frequency justifies it.
class_name ItemRegistry_FUTURE
extends Node
