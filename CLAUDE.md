# OutgrowCrestsTracker - Custom Context

> **IMPORTANT: WOW MIDNIGHT TARGET**
> This addon is built exclusively for **World of Warcraft: Midnight (Patch 12.0.0+)**.
> You **must** follow the new API restrictions and namespaces introduced in Patch 12.0.0.
> See the full API changes here: [https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes](https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes)
> Check API methods https://github.com/Ketho/BlizzardInterfaceResources/blob/live/Resources/GlobalAPI.lua using "gh" CLI command
> Use warcraft.wiki.gg to check for specific methods, for example: https://warcraft.wiki.gg/wiki/API_C_ItemUpgrade.GetHighWatermarkForSlot

Don't co-author your commits.

## Changelog Format

Use this format for CHANGELOG.md entries:

```
# Addon Name

## [v1.0.2](https://github.com/Efymer/<repo>/tree/v1.0.2) (YYYY-MM-DD)

- Description of change — v1.0.2
```

- Heading is the addon display name, not "Changelog"
- Version links point to the GitHub tag
- Date in parentheses
- Each entry ends with ` — vX.Y.Z`

## Addon Purpose

Display per-slot gear upgrade progress toward the "X of the Dawn" crest discount achievements in Midnight Season 1. These achievements unlock a **50% crest cost discount for alts** (up from 33% in Dragonflight/TWW) and allow uptrading crests to the next tier.

## Dawn Achievement Series

All are Feats of Strength added in Patch 12.0.1. Each achievement fires when **every equipment slot** reaches the required item level high watermark.

| Achievement            | ID    | Required iLvl | Crest Discount Unlocked         | Uptrade Unlock                          |
|------------------------|-------|---------------|---------------------------------|-----------------------------------------|
| Adventurer of the Dawn | 61809 | 237           | Adventurer track 50% off alts   | Adventurer Dawncrests -> Veteran        |
| Veteran of the Dawn    | 42767 | 250           | Veteran track 50% off alts      | Veteran Dawncrests -> Champion          |
| Champion of the Dawn   | 42768 | 263           | Champion track 50% off alts     | Champion Dawncrests -> Hero             |
| Hero of the Dawn       | 42769 | 276           | Hero track 50% off alts         | Hero Dawncrests -> Myth                 |
| Myth of the Dawn       | 42770 | 285           | Myth track 50% off alts         | (Final tier)                            |

## Midnight Upgrade System Changes

- Upgrades cost a small amount of **gold** instead of Valorstones.
- Each upgrade requires **20 crests** of the matching type (e.g., Champion track uses Champion Dawncrests).
- **100 crests** can be earned per week.
- All tracks have **6 equal ranks**, no overlapping between tiers.
- Crest cost increases with each rank along a track.
- The character-specific discount (free upgrades for same-ilvl pieces on the same character) is separate from the alt-wide achievement discount.

## Core APIs

### C_ItemUpgrade.GetHighWatermarkForSlot(itemRedundancySlot)
```lua
characterHighWatermark, accountHighWatermark = C_ItemUpgrade.GetHighWatermarkForSlot(slotIndex)
```
- `slotIndex`: `Enum.ItemRedundancySlot` value (0-16)
- Returns two numbers: character-level watermark and account-level watermark
- Added in 10.1.0, available on 12.0.1+
- **Predicates**: MayReturnNothing, SecretArguments, AllowedWhenUntainted

### C_ItemUpgrade.GetHighWatermarkForItem(itemInfo)
```lua
characterHighWatermark, accountHighWatermark = C_ItemUpgrade.GetHighWatermarkForItem(itemIDOrLinkOrName)
```

### C_ItemUpgrade.GetHighWatermarkSlotForItem(itemInfo)
```lua
itemRedundancySlot = C_ItemUpgrade.GetHighWatermarkSlotForItem(itemIDOrLinkOrName)
```

### GetAchievementInfo(achievementID)
```lua
id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe, earnedBy, isStatistic = GetAchievementInfo(achievementID)
```

### Enum.ItemRedundancySlot

| Constant             | Value | Notes                          |
|----------------------|-------|--------------------------------|
| Head                 | 0     |                                |
| Neck                 | 1     |                                |
| Shoulder             | 2     |                                |
| Chest                | 3     |                                |
| Waist                | 4     |                                |
| Legs                 | 5     |                                |
| Feet                 | 6     |                                |
| Wrist                | 7     |                                |
| Hand                 | 8     |                                |
| Finger               | 9     | Single slot for both rings     |
| Trinket              | 10    | Single slot for both trinkets  |
| Cloak                | 11    |                                |
| Twohand              | 12    |                                |
| MainhandWeapon       | 13    |                                |
| OnehandWeapon        | 14    |                                |
| OnehandWeaponSecond  | 15    |                                |
| Offhand              | 16    |                                |

**Note on weapons**: Slots 12-16 cover different weapon configurations. A 2H user only has slot 12 active; dual-wielders use 14+15; sword+shield uses 14+16, etc. The addon needs to handle weapon slot relevance based on class/spec.

## User Macros (Reference)

Champion of the Dawn progress check — prints each slot's watermark, colored by threshold:
```lua
/run local n=tInvert(Enum.ItemRedundancySlot)for i=0,16 do local a=C_ItemUpgrade.GetHighWatermarkForSlot(i)if a and n[i]then print((a>=263 and"\124cffA020F0"or a>=250 and"\124cff0070dd"or"\124cff00ff00")..a.." - "..n[i].."\124r")end end
```

Simpler version checking just Champion (263):
```lua
/run local n=tInvert(Enum.ItemRedundancySlot),a;for i=0,16 do a=C_ItemUpgrade.GetHighWatermarkForSlot(i);local c=(a>=263)and"\124cff00ff00"or"";print(format("%s%d\124r %s",c,a,n[i]))end
```

## Design Notes

- The addon should show which slots are holding back progress toward the next achievement
- Color-code: green for slots meeting threshold, yellow/red for slots below
- Show both character and account watermarks
- Indicate which achievements are already completed
- Weapon slots need special handling — not all 5 weapon slots are relevant for every spec
