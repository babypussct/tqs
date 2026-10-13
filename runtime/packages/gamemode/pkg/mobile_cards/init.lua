-- SPDX-License-Identifier: GPL-3.0-or-later

local extension = Package:new("mobile_cards", Package.CardPack)
extension.extensionName = "gamemode"

extension:loadSkillSkelsByPath("./packages/gamemode/pkg/mobile_cards/skills")

Fk:loadTranslationTable{
  ["mobile_cards"] = "手杀卡牌",
}

extension:addCardSpec("qingnang_book", Card.Heart, 9)
extension:addCardSpec("mobile_seal", Card.Spade, 13)

local qingnang_book = fk.CreateCard{
  name = "qingnang_book",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
  equip_skill = "#qingnang_book_skill",
  on_install = function(self, room, player)
    Treasure.onInstall(self, room, player)
    if self:getMark("qingnang_book_durability") == 0 then
      room:setCardMark(self, "qingnang_book_durability", 3)
    end
  end,
}
Fk:loadTranslationTable{
  ["qingnang_book"] = "青囊书",
  [":qingnang_book"] = "装备牌·宝物<br/>"..
  "<b>宝物技能</b>：锁定技，准备阶段，你加1点体力上限并回复1点体力（耐久度3，耐久度减至0时销毁）。",
}

local mobile_seal = fk.CreateCard{
  name = "mobile_seal",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
  equip_skill = "#mobile_seal_skill",
}
Fk:loadTranslationTable{
  ["mobile_seal"] = "传国玉玺",
  [":mobile_seal"] = "装备牌·宝物<br/>"..
  "<b>宝物技能</b>：锁定技，弃牌阶段开始时，你摸一张牌且手牌上限永久+2，然后若你不为主公，你失去1点体力。",
}

extension:loadCardSkels {
  qingnang_book,
  mobile_seal,
}

return extension
