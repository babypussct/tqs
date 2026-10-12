-- SPDX-License-Identifier: GPL-3.0-or-later

local extension = Package:new("bloodbath_longbench_cards", Package.CardPack)
extension.extensionName = "ol"
extension.game_modes_whitelist = {
  "bloodbath_longbench",
}

extension:loadSkillSkelsByPath("./packages/ol/pkg/ol_gamemode/longbench/cards/skills")

Fk:loadTranslationTable{
  ["bloodbath_longbench_cards"] = "血战长坂坡卡牌",
}

local v11_lb__supply_shortage = fk.CreateCard{
  name = "v11_lb__supply_shortage",
  type = Card.TypeTrick,
  sub_type = Card.SubtypeDelayedTrick,
  skill = "v11_lb__supply_shortage_skill",
}
Fk:loadTranslationTable{
  ["v11_lb__supply_shortage"] = "兵粮寸断",
  [":v11_lb__supply_shortage"] = "延时锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：一名其他角色<br/>"..
  "<b>效果</b>：将【兵粮寸断】置于目标角色判定区里。若判定结果不为♣：摸牌阶段，少摸一张牌；摸牌阶段结束时，除其外的角色各摸一张牌。",

  ["v11_lb__supply_shortage_skill"] = "兵粮寸断",
  ["#v11_lb__supply_shortage_skill"] = "选择一名其他角色，将此牌置于其判定区内。其判定阶段判定：<br/>若结果不为<font color='#CC3131'>♣</font>，"..
  "其摸牌阶段少摸一张牌，除其外的角色各摸一张牌",
}

local v11_lb__crossbow = fk.CreateCard{
  name = "v11_lb__crossbow",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 1,
  equip_skill = "#v11_lb__crossbow_skill",
}
Fk:loadTranslationTable{
  ["v11_lb__crossbow"] = "诸葛连弩",
  [":v11_lb__crossbow"] = "装备牌·武器<br/>"..
  "<b>攻击范围</b>：1<br/>"..
  "<b>武器技能</b>：锁定技，你于出牌阶段内使用【杀】次数上限+3。",
  ["#v11_lb__crossbow_skill"] = "诸葛连弩",
}

extension:loadCardSkels {
  v11_lb__supply_shortage,
  v11_lb__crossbow,
}

extension:addCardSpec("v11_lb__supply_shortage", Card.Spade, 10)
extension:addCardSpec("v11_lb__supply_shortage", Card.Club, 4)

extension:addCardSpec("v11_lb__crossbow", Card.Club, 1)
extension:addCardSpec("v11_lb__crossbow", Card.Diamond, 1)

return extension
