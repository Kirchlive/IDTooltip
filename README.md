# IDTooltip

**Universal ID Tooltip for TurtleWoW**

Shows Item, Gear, Spell, Buff, Debuff and Quest IDs in every tooltip across the entire UI.

## Features

- **Item IDs** everywhere: Bags, Character Frame, Action Bar, Chat Links, Merchant, Quest Rewards, Loot
- **AtlasLoot Support**: Native integration with AtlasLoot Enhanced tooltips (AtlasLootTooltip, AtlasLootTooltip2, AtlasLootCacheTooltip)
- **Spell IDs** with correct ranks: Spellbook (Rank 1 vs Rank 7 = different IDs), Action Bar, Castbar
- **Buff/Debuff IDs**: Default buff bar, Unit Frames, ElkBuffBar, pfUI — any addon that uses GameTooltip
- **Quest IDs**: Chat link popups, quest windows (safe C-call wrappers prevent Chat-Addon crashes)
- **Spell Link IDs**: Vanilla uses "enchant:" format for spell links — correctly detected and labeled as "Spell ID"
- **Zero lag**: One-time SpellRec scan at addon load (~250ms for ~22.000 spells), all hover lookups are instant table reads

<p align="center">
  <img src="https://i.imgur.com/d7wu6AY.png" alt="IDTooltip" width="400"> <img src="https://i.imgur.com/4ESdjrI.png" alt="IDTooltip" width="400">
  <img src="https://i.imgur.com/1cF70q9.png" alt="IDTooltip" width="400"> <img src="https://i.imgur.com/JwRA7Yf.png" alt="IDTooltip" width="400">
</p>



## How It Works

At addon load, IDTooltip scans ~45.000 SpellRec entries and builds a reverse map: `"SpellName|Rank"` -> SpellID. This takes ~250ms once. Every tooltip hover after that is a simple table lookup — zero API calls, zero lag.

For items, the ID is extracted from the item link string. For player buffs, SuperWoW's `GetPlayerBuffID` provides exact IDs. For action bar entries, SuperWoW's `GetActionText` returns the type and ID directly. For quest links, `SetItemRef` captures the quest ID which is then injected via `OnShow`.

## Hooked Tooltip Functions (18+)

| Hook | What |
|---|---|
| `SetBagItem` | Items in bags |
| `SetInventoryItem` | Equipped gear (Character Frame) |
| `SetHyperlink` | Chat item/spell links |
| `ItemRefTooltip.SetHyperlink` | Chat link popup (items/spells) |
| `AtlasLootTooltip.SetHyperlink` | AtlasLoot Enhanced primary tooltip |
| `AtlasLootTooltip2.SetHyperlink` | AtlasLoot Enhanced secondary tooltip |
| `AtlasLootCacheTooltip.SetHyperlink` | AtlasLoot Enhanced cache tooltip |
| `ItemRefTooltip:OnShow` | Quest ID injection (after tooltip build) |
| `SetItemRef` | Quest link capture from chat clicks |
| `OnShow` | Fallback for remaining items |
| `SetUnitBuff` | Buff tooltips on Unit Frames |
| `SetUnitDebuff` | Debuff tooltips on Unit Frames |
| `SetPlayerBuff` | Default buff/debuff bar (top-right icons) |
| `SetSpell` | Spellbook tooltips |
| `SetAction` | Action bar (spells + items via GetActionText) |
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
