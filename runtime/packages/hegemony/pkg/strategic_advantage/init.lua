-- SPDX-License-Identifier: GPL-3.0-or-later

local extension = Package:new("strategic_advantage", Package.CardPack)
extension.extensionName = "hegemony"

local H = require "packages.hegemony.util"

Fk:loadTranslationTable{
  ["strategic_advantage"] = "国战·势备篇",
}

extension.game_modes_whitelist = { 'new_heg_mode' }
-- extension.game_modes_blacklist = {"aaa_role_mode", "m_1v1_mode", "m_1v2_mode", "m_2v2_mode", "zombie_mode", "chaos_mode"}

extension:loadSkillSkelsByPath("./packages/hegemony/pkg/strategic_advantage/skills")

extension:addCardSpec("slash", Card.Heart, 10)
extension:addCardSpec("slash", Card.Heart, 11)
extension:addCardSpec("slash", Card.Spade, 4)
extension:addCardSpec("slash", Card.Spade, 7)
extension:addCardSpec("slash", Card.Spade, 8)
extension:addCardSpec("slash", Card.Club, 4)
extension:addCardSpec("slash", Card.Club, 6)
extension:addCardSpec("slash", Card.Club, 7)
extension:addCardSpec("slash", Card.Club, 8)

extension:addCardSpec("thunder__slash", Card.Spade, 9)
extension:addCardSpec("thunder__slash", Card.Spade, 10)
-- Fk:cloneCard("thunder__slash", Card.Spade, 11)
-- Fk:cloneCard("thunder__slash", Card.Club, 5)

extension:addCardSpec("fire__slash", Card.Diamond, 8)
extension:addCardSpec("fire__slash", Card.Diamond, 9)

extension:addCardSpec("jink", Card.Heart, 4)
extension:addCardSpec("jink", Card.Heart, 5)
-- Fk:cloneCard("jink", Card.Heart, 6)
extension:addCardSpec("jink", Card.Heart, 7)
extension:addCardSpec("jink", Card.Diamond, 6)
extension:addCardSpec("jink", Card.Diamond, 7)
extension:addCardSpec("jink", Card.Diamond, 13)

extension:addCardSpec("peach", Card.Heart, 8)
extension:addCardSpec("peach", Card.Heart, 9)
extension:addCardSpec("peach", Card.Diamond, 2)
-- Fk:cloneCard("peach", Card.Diamond, 3)

-- Fk:cloneCard("analeptic", Card.Spade, 6)
extension:addCardSpec("analeptic", Card.Club, 9)

extension:addCardSpec("nullification", Card.Spade, 13)

extension:addCardSpec("heg__nullification", Card.Diamond, 11)
extension:addCardSpec("heg__nullification", Card.Club, 13)

H.addAllianceCardSpec(extension, "jink", Card.Heart, 6)
H.addAllianceCardSpec(extension, "peach", Card.Diamond, 3)
H.addAllianceCardSpec(extension, "analeptic", Card.Spade, 6)
H.addAllianceCardSpec(extension, "thunder__slash", Card.Spade, 11)
H.addAllianceCardSpec(extension, "thunder__slash", Card.Club, 5)

local drowning = fk.CreateCard{
  name = "sa__drowning",
  skill = "sa__drowning_skill",
  type = Card.TypeTrick,
  is_damage_card = true,
  damage_type = fk.ThunderDamage,
}

extension:addCardSpec("sa__drowning", Card.Heart, 13)
extension:addCardSpec("sa__drowning", Card.Club, 12)

local burningCamps = fk.CreateCard{
  name = "burning_camps",
  type = Card.TypeTrick,
  skill = "burning_camps_skill",
  multiple_targets = true,
  is_damage_card = true,
  damage_type = fk.FireDamage,
}

H.addAllianceCardSpec(extension, "burning_camps", Card.Heart, 12)
H.addAllianceCardSpec(extension, "burning_camps", Card.Spade, 3)
H.addAllianceCardSpec(extension, "burning_camps", Card.Club, 11)

local lureTiger = fk.CreateCard{
  name = "lure_tiger",
  type = Card.TypeTrick,
  skill = "lure_tiger_skill",
  multiple_targets = true,
}

H.addAllianceCardSpec(extension, "lure_tiger", Card.Heart, 2)
H.addAllianceCardSpec(extension, "lure_tiger", Card.Diamond, 10)

local fightTogether = fk.CreateCard{
  name = "fight_together",
  type = Card.TypeTrick,
  skill = "fight_together_skill",
  multiple_targets = true,
  special_skills = { "recast" },
}

extension:addCardSpec("fight_together", Card.Spade, 12)
extension:addCardSpec("fight_together", Card.Club, 10)

local allianceFeast = fk.CreateCard{
  name = "alliance_feast",
  type = Card.TypeTrick,
  skill = "alliance_feast_skill",
  multiple_targets = true,
}

extension:addCardSpec("alliance_feast", Card.Heart, 1)

local threatenEmperor = fk.CreateCard{
  name = "threaten_emperor",
  type = Card.TypeTrick,
  skill = "threaten_emperor_skill",
}

H.addAllianceCardSpec(extension, "threaten_emperor", Card.Diamond, 1)
H.addAllianceCardSpec(extension, "threaten_emperor", Card.Diamond, 4)
H.addAllianceCardSpec(extension, "threaten_emperor", Card.Spade, 1)

local imperialOrder = fk.CreateCard{
  name = "imperial_order",
  type = Card.TypeTrick,
  skill = "imperial_order_skill",
  multiple_targets = true,
}

extension:addCardSpec("imperial_order", Card.Club, 3)

local blade = fk.CreateCard{
  name = "sa__blade",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 3,
  equip_skill = "#sa__blade_skill",
}

extension:addCardSpec("sa__blade", Card.Spade, 5)

local halberd = fk.CreateCard{
  name = "sa__halberd",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 4,
  equip_skill = "#sa__halberd_skill",
}

extension:addCardSpec("sa__halberd", Card.Diamond, 12)

local breastplate = fk.CreateCard{
  name = "sa__breastplate",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeArmor,
  equip_skill = "#sa__breastplate_skill",
}

H.addAllianceCardSpec(extension, "sa__breastplate", Card.Club, 2)

local ironArmor = fk.CreateCard{
  name = "iron_armor",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeArmor,
  equip_skill = "#iron_armor_skill",
}

extension:addCardSpec("iron_armor", Card.Spade, 2)

local jingfan = fk.CreateCard{
  name = "jingfan",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeOffensiveRide,
  equip_skill = "#jingfan_skill",
}

H.addAllianceCardSpec(extension, "jingfan", Card.Heart, 3)

local woodenOx = fk.CreateCard{
  name = "wooden_ox",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
  equip_skill = "wooden_ox_skill",

  on_uninstall = function(self, room, player)
    Treasure.onUninstall(self, room, player)
    player:setSkillUseHistory(self.equip_skill.name, 0, Player.HistoryPhase)
  end,
}

extension:addCardSpec("wooden_ox", Card.Diamond, 5)

local jadeSeal = fk.CreateCard{
  name = "jade_seal",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
  equip_skill = "#jade_seal_skill",
}

extension:loadCardSkels{
  drowning, burningCamps, lureTiger, fightTogether, allianceFeast, threatenEmperor, imperialOrder,
  blade, halberd, breastplate, ironArmor, jingfan, woodenOx, jadeSeal
}
extension:addCardSpec("jade_seal", Card.Club, 1)

return extension
