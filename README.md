# IDTooltip

**Universal ID Tooltip for WoW 1.12 / TurtleWoW**

Shows Item IDs, Spell IDs, Buff IDs and Debuff IDs in every tooltip across the entire UI — zero lag.

## Features

- **Item IDs** everywhere: Bags, Character Frame, Action Bar, Chat Links, Merchant, Quest Rewards, Loot
- **Spell IDs** with correct ranks: Spellbook (Rank 1 vs Rank 7 = different IDs), Action Bar, Castbar
- **Buff/Debuff IDs**: Default buff bar, Unit Frames, ElkBuffBar, pfUI — any addon that uses GameTooltip
- **Zero lag**: One-time SpellRec scan at login (~250ms), all hover lookups are instant table reads

## How It Works

At addon load, IDTooltip scans ~45.000 SpellRec entries and builds a reverse map: `"SpellName|Rank"` → SpellID. This takes ~250ms once. Every tooltip hover after that is a simple table lookup — zero API calls, zero lag.

For items, the ID is extracted from the item link string. For player buffs, SuperWoW's `GetPlayerBuffID` provides exact IDs. For action bar spells, SuperWoW's `GetActionText` returns the spell type and ID directly.

## Hooked Tooltip Functions (14)

| Hook | What |
|---|---|
| `SetBagItem` | Items in bags |
| `SetInventoryItem` | Equipped gear (Character Frame) |
| `SetHyperlink` | Chat item links |
| `ItemRefTooltip.SetHyperlink` | Chat link popup window |
| `OnShow` | Fallback for remaining items |
| `SetUnitBuff` | Buff tooltips on Unit Frames |
| `SetUnitDebuff` | Debuff tooltips on Unit Frames |
| `SetPlayerBuff` | Default buff/debuff bar (top-right icons) |
| `SetSpell` | Spellbook tooltips |
| `SetAction` | Action bar (spells + items) |
| `SetTrackingSpell` | Tracking spell tooltips |
| `SetMerchantItem` | Vendor item tooltips |
| `SetQuestItem` | Quest reward tooltips |
| `SetLootItem` | Loot window tooltips |

## Requirements

- WoW 1.12.1 (Interface 11200)
- TurtleWoW recommended (for SuperWoW/Nampower extended APIs)
- Works without SuperWoW (falls back to name-based lookup)

## Installation

Copy the `IDTooltip` folder to `Interface/AddOns/`.

## Credits

- Original concept: cyaohiri (ItemIDTooltip)
- Extended & rewritten: Tetto & Teto
- Built with ClaudeBridge
