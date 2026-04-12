local addonName, addon = ...

addon.Config = {}

-- Dawn achievement series — each unlocks 50% crest discount for alts
-- and allows uptrading crests to the next tier
addon.Config.achievements = {
    {
        id    = 61809,
        name  = "Adventurer of the Dawn",
        tier  = "Adventurer",
        ilvl  = 237,
        color = { 0.12, 1.00, 0.00 },
    },
    {
        id    = 42767,
        name  = "Veteran of the Dawn",
        tier  = "Veteran",
        ilvl  = 250,
        color = { 0.00, 0.44, 0.87 },
    },
    {
        id    = 42768,
        name  = "Champion of the Dawn",
        tier  = "Champion",
        ilvl  = 263,
        color = { 0.63, 0.13, 0.94 },
    },
    {
        id    = 42769,
        name  = "Hero of the Dawn",
        tier  = "Hero",
        ilvl  = 276,
        color = { 1.00, 0.50, 0.00 },
    },
    {
        id    = 42770,
        name  = "Myth of the Dawn",
        tier  = "Myth",
        ilvl  = 285,
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
