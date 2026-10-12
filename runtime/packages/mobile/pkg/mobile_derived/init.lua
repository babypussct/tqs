-- SPDX-License-Identifier: GPL-3.0-or-later

local extension = Package:new("mobile_derived", Package.CardPack)
extension.extensionName = "mobile"

extension:loadSkillSkelsByPath("./packages/mobile/pkg/mobile_derived/skills")

Fk:loadTranslationTable{
  ["mobile_derived"] = "手杀衍生牌",
}

local ex_crossbow = fk.CreateCard{
  name = "&ex_crossbow",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 3,
  equip_skill = "#ex_crossbow_skill",
}
extension:addCardSpec("ex_crossbow", Card.Club, 1)
Fk:loadTranslationTable{
  ["ex_crossbow"] = "元戎精械弩",
  [":ex_crossbow"] = "装备牌·武器<br/><b>攻击范围</b>：3<br/><b>武器技能</b>：锁定技，你于出牌阶段内使用【杀】无次数限制。",
}

local ex_eight_diagram = fk.CreateCard{
  name = "&ex_eight_diagram",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeArmor,
  equip_skill = "#ex_eight_diagram_skill",
}
extension:addCardSpec("ex_eight_diagram", Card.Spade, 2)
Fk:loadTranslationTable{
  ["ex_eight_diagram"] = "先天八卦阵",
  [":ex_eight_diagram"] = "装备牌·防具<br/><b>防具技能</b>：当你需要使用或打出一张【闪】时，你可以进行判定：若结果不为♠，"..
  "视为你使用或打出了一张【闪】。",
}

local ex_nioh_shield = fk.CreateCard{
  name = "&ex_nioh_shield",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeArmor,
  equip_skill = "#ex_nioh_shield_skill",
}
extension:addCardSpec("ex_nioh_shield", Card.Club, 2)
Fk:loadTranslationTable{
  ["ex_nioh_shield"] = "仁王金刚盾",
  [":ex_nioh_shield"] = "装备牌·防具<br/><b>防具技能</b>：锁定技，黑色【杀】和<font color='red'>♥</font>【杀】对你无效。",
}

local ex_vine = fk.CreateCard{
  name = "&ex_vine",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeArmor,
  equip_skill = "#ex_vine_skill",
}
extension:addCardSpec("ex_vine", Card.Club, 2)
Fk:loadTranslationTable{
  ["ex_vine"] = "桐油百韧甲",
  [":ex_vine"] = "装备牌·防具<br/><b>防具技能</b>：锁定技。【南蛮入侵】、【万箭齐发】和普通【杀】对你无效。你不能被横置。"..
  "当你受到火焰伤害时，此伤害+1。",
}

local ex_silver_lion = fk.CreateCard{
  name = "&ex_silver_lion",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeArmor,
  equip_skill = "#ex_silver_lion_skill",
}
extension:addCardSpec("ex_silver_lion", Card.Club, 1)
Fk:loadTranslationTable{
  ["ex_silver_lion"] = "照月狮子盔",
  [":ex_silver_lion"] = "装备牌·防具<br/><b>防具技能</b>：锁定技，当你受到伤害时，若此伤害大于1点，防止多余的伤害。当你失去装备区里的"..
  "【照月狮子盔】后，你回复1点体力并摸两张牌。",
}

local catapult = fk.CreateCard{
  name = "&mobile__catapult",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 9,
  equip_skill = "#mobile__catapult_skill",
}
extension:addCardSpec("mobile__catapult", Card.Diamond, 9)
Fk:loadTranslationTable{
  ["mobile__catapult"] = "霹雳车",
  [":mobile__catapult"] = "装备牌·武器<br/><b>攻击范围</b>：9<br/><b>武器技能</b>：当你对其他角色造成伤害后，你可以弃置其装备区内的所有牌。",
}

local offensive_siege_engine = fk.CreateCard{
  name = "&offensive_siege_engine",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 9,
  equip_skill = "#offensive_siege_engine_skill",
  on_install = function(self, room, player)
    local cardMark = self:getMark("offensive_siege_engine_durability")
    if cardMark == 0 then
      room:setPlayerMark(player, "@offensive_siege_engine_durability", 2)
      room:setCardMark(self, "offensive_siege_engine_durability", 2)
    else
      room:setPlayerMark(player, "@offensive_siege_engine_durability", cardMark)
    end
    Weapon.onInstall(self, room, player)
  end,
  on_uninstall = function(self, room, player)
    room:setCardMark(self, "offensive_siege_engine_durability", player:getMark("@offensive_siege_engine_durability"))
    room:setPlayerMark(player, "@offensive_siege_engine_durability", 0)
    Weapon.onUninstall(self, room, player)
  end,
}
extension:addCardSpec("offensive_siege_engine", Card.Diamond, 1)
Fk:loadTranslationTable{
  ["offensive_siege_engine"] = "大攻车·进击",
  [":offensive_siege_engine"] = "装备牌·武器<br/><b>攻击范围</b>：9<br /><b>耐久度</b>：2<br />" ..
  "<b>武器技能</b>：当此牌进入装备区后，弃置你装备区里的其他牌；当其他装备牌进入装备区前，改为将之置入弃牌堆；" ..
  "当你造成伤害时，你可以令此牌减1点耐久度，令此伤害+X（X为游戏轮数且至多为3）；当此牌不因“渠冲”而离开装备区时，防止之，然后此牌-1点耐久度；" ..
  "当此牌耐久度减至0时，销毁此牌。",
}

local defensive_siege_engine = fk.CreateCard{
  name = "&defensive_siege_engine",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 9,
  equip_skill = "#defensive_siege_engine_skill",
  on_install = function(self, room, player)
    local cardMark = self:getMark("defensive_siege_engine_durability")
    if cardMark == 0 then
      room:setPlayerMark(player, "@defensive_siege_engine_durability", 3)
      room:setCardMark(self, "defensive_siege_engine_durability", 3)
    else
      room:setPlayerMark(player, "@defensive_siege_engine_durability", cardMark)
    end
    Weapon.onInstall(self, room, player)
  end,
  on_uninstall = function(self, room, player)
    room:setCardMark(self, "defensive_siege_engine_durability", player:getMark("@defensive_siege_engine_durability"))
    room:setPlayerMark(player, "@defensive_siege_engine_durability", 0)
    Weapon.onUninstall(self, room, player)
  end,
}
extension:addCardSpec("defensive_siege_engine", Card.Diamond, 1)
Fk:loadTranslationTable{
  ["defensive_siege_engine"] = "大攻车·守御",
  [":defensive_siege_engine"] = "装备牌·武器<br/><b>攻击范围</b>：9<br/><b>耐久度</b>：3<br/>" ..
  "<b>武器技能</b>：当此牌进入装备区后，弃置你装备区里的其他牌；当其他装备牌进入装备区前，改为将之置入弃牌堆；" ..
  "当你受到伤害时，此牌减等量点耐久度（不足则全减），令此伤害-X（X为减少的耐久度）；当此牌不因“渠冲”而离开装备区时，防止之，然后此牌减1点耐久度；" ..
  "当此牌耐久度减至0时，销毁此牌。",
}

local xuanjian_sword = fk.CreateCard{
  name = "&xuanjian_sword",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 3,
  equip_skill = "xuanjian_sword_skill&",
}
extension:addCardSpec("xuanjian_sword", Card.Spade, 9)
Fk:loadTranslationTable{
  ["xuanjian_sword"] = "玄剑",
  [":xuanjian_sword"] = "装备牌·武器<br/><b>攻击范围</b>：3<br/><b>武器技能</b>：你可以将一种花色的所有手牌当【杀】使用。",
}

local liulongcanjia = fk.CreateCard{
  name = "&m_liuyi__liulongcanjia",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
  equip_skill = "#m_liuyi__liulongcanjia_skill",
}
extension:addCardSpec("m_liuyi__liulongcanjia", Card.Heart, 13)
Fk:loadTranslationTable{
  ["m_liuyi__liulongcanjia"] = "六龙骖驾",
  [":m_liuyi__liulongcanjia"] = "装备牌·宝物牌<br/><b>宝物技能</b>：你计算与其他角色的距离-X；其他角色计算与你的距离+X（X为场上点数为K的牌数）。",
}

extension:loadCardSkels {
  ex_crossbow,
  ex_eight_diagram,
  ex_nioh_shield,
  ex_vine,
  ex_silver_lion,
  catapult,
  offensive_siege_engine,
  defensive_siege_engine,
  xuanjian_sword,
  liulongcanjia,
}

return extension
