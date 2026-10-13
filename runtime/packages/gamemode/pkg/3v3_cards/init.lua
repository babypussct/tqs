-- SPDX-License-Identifier: GPL-3.0-or-later

local extension = Package:new("3v3_cards", Package.CardPack)
extension.extensionName = "gamemode"
extension.game_modes_whitelist = {
  "m_3v3_mode",
}

extension:loadSkillSkelsByPath("./packages/gamemode/pkg/3v3_cards/skills")

Fk:loadTranslationTable{
  ["3v3_cards"] = "3v3卡牌",
}

extension:addCardSpec("slash", Card.Spade, 7)
extension:addCardSpec("slash", Card.Spade, 8)
extension:addCardSpec("slash", Card.Spade, 8)
extension:addCardSpec("slash", Card.Spade, 9)
extension:addCardSpec("slash", Card.Spade, 9)
extension:addCardSpec("slash", Card.Spade, 10)
extension:addCardSpec("slash", Card.Heart, 10)
extension:addCardSpec("slash", Card.Club, 3)
extension:addCardSpec("slash", Card.Club, 4)
extension:addCardSpec("slash", Card.Club, 6)
extension:addCardSpec("slash", Card.Club, 8)
extension:addCardSpec("slash", Card.Club, 9)
extension:addCardSpec("slash", Card.Club, 9)
extension:addCardSpec("slash", Card.Club, 10)
extension:addCardSpec("slash", Card.Club, 10)
extension:addCardSpec("slash", Card.Club, 11)
extension:addCardSpec("slash", Card.Club, 11)
extension:addCardSpec("slash", Card.Diamond, 6)
extension:addCardSpec("slash", Card.Diamond, 10)
extension:addCardSpec("slash", Card.Diamond, 13)

extension:addCardSpec("thunder__slash", Card.Spade, 4)
extension:addCardSpec("thunder__slash", Card.Spade, 5)
extension:addCardSpec("thunder__slash", Card.Spade, 6)
extension:addCardSpec("thunder__slash", Card.Club, 5)
extension:addCardSpec("thunder__slash", Card.Club, 6)
extension:addCardSpec("thunder__slash", Card.Club, 7)
extension:addCardSpec("thunder__slash", Card.Club, 8)

extension:addCardSpec("fire__slash", Card.Heart, 4)
extension:addCardSpec("fire__slash", Card.Heart, 10)
extension:addCardSpec("fire__slash", Card.Diamond, 4)
extension:addCardSpec("fire__slash", Card.Diamond, 5)

extension:addCardSpec("jink", Card.Heart, 2)
extension:addCardSpec("jink", Card.Heart, 2)
extension:addCardSpec("jink", Card.Heart, 9)
extension:addCardSpec("jink", Card.Heart, 11)
extension:addCardSpec("jink", Card.Heart, 13)
extension:addCardSpec("jink", Card.Diamond, 2)
extension:addCardSpec("jink", Card.Diamond, 6)
extension:addCardSpec("jink", Card.Diamond, 7)
extension:addCardSpec("jink", Card.Diamond, 7)
extension:addCardSpec("jink", Card.Diamond, 8)
extension:addCardSpec("jink", Card.Diamond, 8)
extension:addCardSpec("jink", Card.Diamond, 9)
extension:addCardSpec("jink", Card.Diamond, 10)
extension:addCardSpec("jink", Card.Diamond, 11)
extension:addCardSpec("jink", Card.Diamond, 11)

extension:addCardSpec("peach", Card.Heart, 4)
extension:addCardSpec("peach", Card.Heart, 6)
extension:addCardSpec("peach", Card.Heart, 7)
extension:addCardSpec("peach", Card.Heart, 8)
extension:addCardSpec("peach", Card.Heart, 9)
extension:addCardSpec("peach", Card.Diamond, 2)
extension:addCardSpec("peach", Card.Diamond, 3)
extension:addCardSpec("peach", Card.Diamond, 12)

extension:addCardSpec("analeptic", Card.Spade, 3)
extension:addCardSpec("analeptic", Card.Club, 3)
extension:addCardSpec("analeptic", Card.Diamond, 9)

extension:addCardSpec("dismantlement", Card.Spade, 3)
extension:addCardSpec("dismantlement", Card.Spade, 4)
extension:addCardSpec("dismantlement", Card.Spade, 12)
extension:addCardSpec("dismantlement", Card.Heart, 12)

extension:addCardSpec("snatch", Card.Spade, 11)
extension:addCardSpec("snatch", Card.Diamond, 3)
extension:addCardSpec("snatch", Card.Diamond, 4)

extension:addCardSpec("duel", Card.Spade, 1)
extension:addCardSpec("duel", Card.Diamond, 1)

extension:addCardSpec("collateral", Card.Club, 12)
extension:addCardSpec("collateral", Card.Club, 13)

extension:addCardSpec("v33__ex_nihilo", Card.Heart, 7)
extension:addCardSpec("v33__ex_nihilo", Card.Heart, 8)
extension:addCardSpec("v33__ex_nihilo", Card.Heart, 11)

extension:addCardSpec("nullification", Card.Spade, 13)
extension:addCardSpec("nullification", Card.Heart, 1)
extension:addCardSpec("nullification", Card.Club, 12)
extension:addCardSpec("nullification", Card.Diamond, 12)

extension:addCardSpec("savage_assault", Card.Spade, 7)
extension:addCardSpec("savage_assault", Card.Club, 7)

extension:addCardSpec("archery_attack", Card.Heart, 1)

extension:addCardSpec("god_salvation", Card.Heart, 1)

extension:addCardSpec("amazing_grace", Card.Heart, 3)

extension:addCardSpec("indulgence", Card.Spade, 6)
extension:addCardSpec("indulgence", Card.Heart, 6)

extension:addCardSpec("iron_chain", Card.Spade, 11)
extension:addCardSpec("iron_chain", Card.Club, 12)
extension:addCardSpec("iron_chain", Card.Club, 13)

extension:addCardSpec("fire_attack", Card.Heart, 3)
extension:addCardSpec("fire_attack", Card.Diamond, 12)

extension:addCardSpec("supply_shortage", Card.Spade, 10)
extension:addCardSpec("supply_shortage", Card.Club, 4)

extension:addCardSpec("xbow", Card.Club, 1)

extension:addCardSpec("double_swords", Card.Spade, 2)
extension:addCardSpec("ice_sword", Card.Spade, 2)
extension:addCardSpec("guding_blade", Card.Spade, 1)
extension:addCardSpec("blade", Card.Spade, 5)
extension:addCardSpec("spear", Card.Spade, 12)
extension:addCardSpec("axe", Card.Diamond, 5)
extension:addCardSpec("fan", Card.Diamond, 1)
extension:addCardSpec("kylin_bow", Card.Heart, 5)

extension:addCardSpec("eight_diagram", Card.Club, 2)
extension:addCardSpec("vine", Card.Club, 2)
extension:addCardSpec("silver_lion", Card.Club, 1)

extension:addCardSpec("dilu", Card.Club, 5)
extension:addCardSpec("zhuahuangfeidian", Card.Heart, 13)
extension:addCardSpec("hualiu", Card.Diamond, 13)

extension:addCardSpec("chitu", Card.Heart, 5)
extension:addCardSpec("dayuan", Card.Spade, 13)

local ex_nihilo = fk.CreateCard{
  name = "v33__ex_nihilo",
  type = Card.TypeTrick,
  skill = "v33__ex_nihilo_skill",
}
Fk:loadTranslationTable{
  ["v33__ex_nihilo"] = "无中生有",
  [":v33__ex_nihilo"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：你<br/>"..
  "<b>效果</b>：目标角色摸两张牌。若己方角色数少于敌方角色数，则多摸一张牌。",

  ["v33__ex_nihilo_skill"] = "无中生有",
  ["#v33__ex_nihilo_skill"] = "摸%arg张牌",
}

local xbow = fk.CreateCard{
  name = "xbow",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 1,
  equip_skill = "#xbow_skill",
}
Fk:loadTranslationTable{
  ["xbow"] = "连弩",
  [":xbow"] = "装备牌·武器<br/>"..
  "<b>攻击范围</b>：1<br/>"..
  "<b>武器技能</b>：锁定技，你于出牌阶段内使用【杀】次数上限+3。",
  ["#xbow_skill"] = "连弩",
}

extension:loadCardSkels {
  ex_nihilo,
  xbow,
}

return extension
