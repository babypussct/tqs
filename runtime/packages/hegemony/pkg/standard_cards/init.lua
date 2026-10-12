-- SPDX-License-Identifier: GPL-3.0-or-later

local extension = Package:new("hegemony_cards", Package.CardPack)
extension.extensionName = "hegemony"

Fk:loadTranslationTable{
  ["hegemony_cards"] = "国战标准版",
}

extension.game_modes_whitelist = { 'new_heg_mode' }
-- extension.game_modes_blacklist = {"aaa_role_mode", "m_1v1_mode", "m_1v2_mode", "m_2v2_mode", "zombie_mode", "chaos_mode"}

extension:loadSkillSkelsByPath("./packages/hegemony/pkg/standard_cards/skills")

extension:addCardSpec("slash", Card.Spade, 5)
extension:addCardSpec("slash", Card.Spade, 7)
extension:addCardSpec("slash", Card.Spade, 8)
extension:addCardSpec("slash", Card.Spade, 8)
extension:addCardSpec("slash", Card.Spade, 9)
extension:addCardSpec("slash", Card.Spade, 10)
extension:addCardSpec("slash", Card.Spade, 11)
extension:addCardSpec("slash", Card.Heart, 10)
extension:addCardSpec("slash", Card.Heart, 12)
extension:addCardSpec("slash", Card.Club, 2)
extension:addCardSpec("slash", Card.Club, 3)
extension:addCardSpec("slash", Card.Club, 4)
extension:addCardSpec("slash", Card.Club, 5)
extension:addCardSpec("slash", Card.Club, 8)
extension:addCardSpec("slash", Card.Club, 9)
extension:addCardSpec("slash", Card.Club, 10)
extension:addCardSpec("slash", Card.Club, 11)
extension:addCardSpec("slash", Card.Club, 11)
extension:addCardSpec("slash", Card.Diamond, 10)
extension:addCardSpec("slash", Card.Diamond, 11)
extension:addCardSpec("slash", Card.Diamond, 12)

extension:addCardSpec("thunder__slash", Card.Spade, 6)
extension:addCardSpec("thunder__slash", Card.Spade, 7)
extension:addCardSpec("thunder__slash", Card.Club, 6)
extension:addCardSpec("thunder__slash", Card.Club, 7)
extension:addCardSpec("thunder__slash", Card.Club, 8)

extension:addCardSpec("fire__slash", Card.Heart, 4)
extension:addCardSpec("fire__slash", Card.Diamond, 4)
extension:addCardSpec("fire__slash", Card.Diamond, 5)

extension:addCardSpec("jink", Card.Heart, 2)
extension:addCardSpec("jink", Card.Heart, 11)
extension:addCardSpec("jink", Card.Heart, 13)
extension:addCardSpec("jink", Card.Diamond, 2)
extension:addCardSpec("jink", Card.Diamond, 3)
extension:addCardSpec("jink", Card.Diamond, 6)
extension:addCardSpec("jink", Card.Diamond, 7)
extension:addCardSpec("jink", Card.Diamond, 7)
extension:addCardSpec("jink", Card.Diamond, 8)
extension:addCardSpec("jink", Card.Diamond, 8)
extension:addCardSpec("jink", Card.Diamond, 9)
extension:addCardSpec("jink", Card.Diamond, 10)
extension:addCardSpec("jink", Card.Diamond, 11)
extension:addCardSpec("jink", Card.Diamond, 13)

extension:addCardSpec("peach", Card.Heart, 4)
extension:addCardSpec("peach", Card.Heart, 6)
extension:addCardSpec("peach", Card.Heart, 7)
extension:addCardSpec("peach", Card.Heart, 8)
extension:addCardSpec("peach", Card.Heart, 9)
extension:addCardSpec("peach", Card.Heart, 10)
extension:addCardSpec("peach", Card.Heart, 12)
extension:addCardSpec("peach", Card.Diamond, 2)

extension:addCardSpec("analeptic", Card.Spade, 9)
extension:addCardSpec("analeptic", Card.Club, 9)
extension:addCardSpec("analeptic", Card.Diamond, 9)


extension:addCardSpec("dismantlement", Card.Spade, 3)
extension:addCardSpec("dismantlement", Card.Spade, 4)
extension:addCardSpec("dismantlement", Card.Heart, 12)
extension:addCardSpec("snatch", Card.Diamond, 3)
extension:addCardSpec("snatch", Card.Spade, 3)
extension:addCardSpec("snatch", Card.Spade, 4)
extension:addCardSpec("duel", Card.Spade, 1)
extension:addCardSpec("duel", Card.Club, 1)
extension:addCardSpec("collateral", Card.Club, 12)
extension:addCardSpec("ex_nihilo", Card.Heart, 7)
extension:addCardSpec("ex_nihilo", Card.Heart, 8)
extension:addCardSpec("nullification", Card.Spade, 11)
extension:addCardSpec("savage_assault", Card.Spade, 13)
extension:addCardSpec("savage_assault", Card.Club, 7)
extension:addCardSpec("archery_attack", Card.Heart, 1)
extension:addCardSpec("god_salvation", Card.Heart, 1)
extension:addCardSpec("amazing_grace", Card.Heart, 3)
extension:addCardSpec("lightning", Card.Spade, 1)
extension:addCardSpec("indulgence", Card.Heart, 6)
extension:addCardSpec("indulgence", Card.Club, 6)
extension:addCardSpec("fire_attack", Card.Heart, 2)
extension:addCardSpec("fire_attack", Card.Heart, 3)
extension:addCardSpec("iron_chain", Card.Spade, 12)
extension:addCardSpec("iron_chain", Card.Club, 12)
extension:addCardSpec("iron_chain", Card.Club, 13)
extension:addCardSpec("supply_shortage", Card.Spade, 10)
extension:addCardSpec("supply_shortage", Card.Club, 10)

local befriendAttacking = fk.CreateCard{
  name = "befriend_attacking",
  skill = "befriend_attacking_skill",
  type = Card.TypeTrick,
}

extension:addCardSpec("befriend_attacking", Card.Heart, 9)

local knownBoth = fk.CreateCard{
  name = "known_both",
  skill = "known_both_skill",
  type = Card.TypeTrick,
  special_skills = {"recast"},
}

extension:addCardSpec("known_both", Card.Club, 3)
extension:addCardSpec("known_both", Card.Club, 4)

local awaitExhausted = fk.CreateCard{
  name = "await_exhausted",
  skill = "await_exhausted_skill",
  multiple_targets = true,
  type = Card.TypeTrick,
}

extension:addCardSpec("await_exhausted", Card.Heart, 11)
extension:addCardSpec("await_exhausted", Card.Diamond, 4)

local hegNullification = fk.CreateCard{
  name = "heg__nullification",
  type = Card.TypeTrick,
  skill = "heg__nullification_skill",
  is_passive = true,
}

extension:addCardSpec("heg__nullification", Card.Club, 13)
extension:addCardSpec("heg__nullification", Card.Diamond, 12)

extension:addCardSpec("crossbow", Card.Diamond, 1)
extension:addCardSpec("qinggang_sword", Card.Spade, 6)
extension:addCardSpec("ice_sword", Card.Spade, 2)
extension:addCardSpec("double_swords", Card.Spade, 2)

local sixSwords = fk.CreateCard{
  name = "six_swords",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 2,
  equip_skill = "#six_swords_skill",
}

extension:addCardSpec("six_swords", Card.Diamond, 6)

extension:addCardSpec("spear", Card.Spade, 12)
extension:addCardSpec("axe", Card.Diamond, 5)

local triblade = fk.CreateCard{
  name = "triblade",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 3,
  equip_skill = "#triblade_skill",
}

extension:loadCardSkels{
  befriendAttacking, knownBoth, awaitExhausted, hegNullification,
  sixSwords, triblade
}
extension:addCardSpec("triblade", Card.Diamond, 12)

extension:addCardSpec("fan", Card.Diamond, 1)
extension:addCardSpec("kylin_bow", Card.Heart, 5)

extension:addCardSpec("eight_diagram", Card.Spade, 2)
extension:addCardSpec("nioh_shield", Card.Club, 2)
extension:addCardSpec("silver_lion", Card.Club, 1)
extension:addCardSpec("vine", Card.Club, 2)

extension:addCardSpec("dilu", Card.Club, 5)
extension:addCardSpec("jueying", Card.Spade, 5)
extension:addCardSpec("zhuahuangfeidian", Card.Heart, 13)
extension:addCardSpec("chitu", Card.Heart, 5)
extension:addCardSpec("dayuan", Card.Spade, 13)
extension:addCardSpec("zixing", Card.Diamond, 13)

return extension
