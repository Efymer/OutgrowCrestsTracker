local addonName, addon = ...

addon.Config = {}

-- Mist achievement series (Midnight Season 2, 12.1.0) — each unlocks 50% crest
-- discount for alts and allows uptrading Mistcrests to the next tier.
-- Thresholds from the achievement criteria trees (Achievement DB2, build 12.1.0.69933).
-- Myth of the Mist is officially an average item level of 331; like the Season 1
-- Myth tier, it is tracked here per slot.
addon.Config.achievements = {
    {
        id    = 62410,
        name  = "Adventurer of the Mist",
        tier  = "Adventurer",
        ilvl  = 282,
        color = { 0.12, 1.00, 0.00 },
    },
    {
        id    = 62411,
        name  = "Veteran of the Mist",
        tier  = "Veteran",
        ilvl  = 295,
        color = { 0.00, 0.44, 0.87 },
    },
    {
        id    = 62412,
        name  = "Champion of the Mist",
        tier  = "Champion",
        ilvl  = 308,
        color = { 0.63, 0.13, 0.94 },
    },
    {
        id    = 62414,
        name  = "Hero of the Mist",
        tier  = "Hero",
        ilvl  = 321,
        color = { 1.00, 0.50, 0.00 },
    },
    {
        id    = 62416,
        name  = "Myth of the Mist",
        tier  = "Myth",
        ilvl  = 331,
        color = { 1.00, 0.00, 0.00 },
    },
}

-- Weapon groups — achievement requires ANY one complete group to meet threshold
addon.Config.weaponGroups = {
    { 12 },       -- Two-Hand
    { 13, 16 },   -- Main Hand + Off Hand (shield/caster offhand)
    { 14, 15 },   -- Dual Wield
}

-- Enum.ItemRedundancySlot display names
-- Slots 12-16 are weapon variants; only the active group matters
addon.Config.slotNames = {
    [0]  = "Head",
    [1]  = "Neck",
    [2]  = "Shoulder",
    [3]  = "Chest",
    [4]  = "Waist",
    [5]  = "Legs",
    [6]  = "Feet",
    [7]  = "Wrist",
    [8]  = "Hands",
    [9]  = "Finger",
    [10] = "Trinket",
    [11] = "Back",
    [12] = "Two-Hand",
    [13] = "Main Hand",
    [14] = "One-Hand",
    [15] = "One-Hand (2)",
    [16] = "Off Hand",
}
