-- SPDX-License-Identifier: GPL-3.0-or-later

local extension = Package:new("1v1_cards", Package.CardPack)
extension.extensionName = "gamemode"
extension.game_modes_whitelist = {
  "m_1v1_mode",
}

extension:loadSkillSkelsByPath("./packages/gamemode/pkg/1v1_cards/skills")

Fk:loadTranslationTable{
  ["1v1_cards"] = "1v1卡牌",
}

extension:addCardSpec("slash", Card.Spade, 5)
extension:addCardSpec("slash", Card.Spade, 7)
extension:addCardSpec("slash", Card.Spade, 8)
extension:addCardSpec("slash", Card.Spade, 10)
extension:addCardSpec("slash", Card.Heart, 10)
extension:addCardSpec("slash", Card.Heart, 11)
extension:addCardSpec("slash", Card.Club, 4)
extension:addCardSpec("slash", Card.Club, 5)
extension:addCardSpec("slash", Card.Club, 6)
extension:addCardSpec("slash", Card.Club, 8)
extension:addCardSpec("slash", Card.Club, 9)
extension:addCardSpec("slash", Card.Club, 9)
extension:addCardSpec("slash", Card.Club, 11)
extension:addCardSpec("slash", Card.Diamond, 6)
extension:addCardSpec("slash", Card.Diamond, 9)
extension:addCardSpec("slash", Card.Diamond, 13)

extension:addCardSpec("jink", Card.Heart, 2)
extension:addCardSpec("jink", Card.Heart, 5)
extension:addCardSpec("jink", Card.Diamond, 2)
extension:addCardSpec("jink", Card.Diamond, 3)
extension:addCardSpec("jink", Card.Diamond, 7)
extension:addCardSpec("jink", Card.Diamond, 8)
extension:addCardSpec("jink", Card.Diamond, 10)
extension:addCardSpec("jink", Card.Diamond, 11)

extension:addCardSpec("peach", Card.Heart, 3)
extension:addCardSpec("peach", Card.Heart, 4)
extension:addCardSpec("peach", Card.Heart, 9)
extension:addCardSpec("peach", Card.Diamond, 12)

extension:addCardSpec("drowning", Card.Club, 7)

extension:addCardSpec("v11__dismantlement", Card.Spade, 3)
extension:addCardSpec("v11__dismantlement", Card.Spade, 12)
extension:addCardSpec("v11__dismantlement", Card.Heart, 12)

extension:addCardSpec("snatch", Card.Spade, 4)
extension:addCardSpec("snatch", Card.Spade, 11)
extension:addCardSpec("snatch", Card.Diamond, 4)

extension:addCardSpec("duel", Card.Spade, 1)
extension:addCardSpec("duel", Card.Club, 1)

extension:addCardSpec("nullification", Card.Heart, 13)
extension:addCardSpec("nullification", Card.Club, 13)

extension:addCardSpec("savage_assault", Card.Spade, 13)

extension:addCardSpec("archery_attack", Card.Heart, 1)

extension:addCardSpec("indulgence", Card.Heart, 6)

extension:addCardSpec("supply_shortage", Card.Club, 12)

extension:addCardSpec("blade", Card.Spade, 6)
extension:addCardSpec("ice_sword", Card.Spade, 9)
extension:addCardSpec("spear", Card.Spade, 12)
extension:addCardSpec("crossbow", Card.Diamond, 1)
extension:addCardSpec("axe", Card.Diamond, 5)
extension:addCardSpec("eight_diagram", Card.Spade, 2)
extension:addCardSpec("nioh_shield", Card.Club, 2)

local dismantlement = fk.CreateCard{
  name = "v11__dismantlement",
  type = Card.TypeTrick,
  skill = "v11__dismantlement_skill",
}
Fk:loadTranslationTable{
  ["v11__dismantlement"] = "过河拆桥",
  [":v11__dismantlement"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：一名有牌的其他角色<br/>"..
  "<b>效果</b>：你选择一项：弃置其装备区里的一张牌；或观看其所有手牌并弃置其中一张。",

  ["v11__dismantlement_skill"] = "过河拆桥",
  ["#v11__dismantlement_skill"] = "选择一名有牌的其他角色，弃置其装备区一张牌，或观看并弃置其一张手牌",
}

extension:loadCardSkels {
  dismantlement,
}

return extension
