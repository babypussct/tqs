-- SPDX-License-Identifier: GPL-3.0-or-later

local extension = Package:new("derived_cards", Package.CardPack)
extension.extensionName = "gamemode"

extension:loadSkillSkelsByPath("./packages/gamemode/pkg/derived_cards/skills")

Fk:loadTranslationTable{
  ["derived_cards"] = "衍生牌",
}

local shade = fk.CreateCard{
  name = "&shade",
  type = Card.TypeBasic,
  skill = "shade_skill",
  is_passive = true,
}
extension:addCardSpec("shade", Card.Spade, 1)
Fk:loadTranslationTable{
  ["shade"] = "影",
  [":shade"] = "基本牌<br/>"..
  "<b>效果</b>：没有效果，不能被使用。<br/>当【影】进入弃牌堆后移出游戏。<br/>当一名角色获得【影】时，均为从游戏外获得♠A的【影】。",
}

local honey_trap = fk.CreateCard{
  name = "&honey_trap",
  type = Card.TypeTrick,
  skill = "honey_trap_skill",
  is_damage_card = true,
  damage_type = fk.NormalDamage,
}
extension:addCardSpec("honey_trap")
Fk:loadTranslationTable{
  ["honey_trap"] = "美人计",
  [":honey_trap"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：一名有手牌的其他男性角色<br/><b>效果</b>：所有女性角色获得"..
  "目标角色的一张手牌并交给你一张手牌，然后你与目标中手牌数少的角色对手牌数多的角色造成1点伤害。",
}

local daggar_in_smile = fk.CreateCard{
  name = "&daggar_in_smile",
  type = Card.TypeTrick,
  skill = "daggar_in_smile_skill",
  is_damage_card = true,
  damage_type = fk.NormalDamage,
}
extension:addCardSpec("daggar_in_smile")
Fk:loadTranslationTable{
  ["daggar_in_smile"] = "笑里藏刀",
  [":daggar_in_smile"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：一名其他角色<br/><b>效果</b>：目标角色摸X张牌（X为其已损失体力值"..
  "且至多为5），然后你对其造成1点伤害。",
}

local underhanding = fk.CreateCard{
  name = "&underhanding",
  skill = "underhanding_skill",
  type = Card.TypeTrick,
  multiple_targets = true,
}
Fk:loadTranslationTable{
  ["underhanding"] = "瞒天过海",
  [":underhanding"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：一至两名区域内有牌的其他角色<br/>"..
  "<b>效果</b>：你依次获得目标角色区域内的一张牌，然后依次交给目标角色一张牌。<br/>【瞒天过海】不计入你的手牌上限。",
}
extension:addCardSpec("underhanding", Card.Heart, 5)
extension:addCardSpec("underhanding", Card.Club, 5)
extension:addCardSpec("underhanding", Card.Spade, 5)
extension:addCardSpec("underhanding", Card.Diamond, 5)

local redistribute = fk.CreateCard{
  name = "&redistribute",
  skill = "redistribute_skill",
  type = Card.TypeTrick,
  special_skills = { "recast" },
  multiple_targets = true,
}
extension:addCardSpec("redistribute", Card.Spade, 6)
extension:addCardSpec("redistribute", Card.Club, 6)
extension:addCardSpec("redistribute", Card.Heart, 6)
extension:addCardSpec("redistribute", Card.Diamond, 6)
Fk:loadTranslationTable{
  ["redistribute"] = "调剂盐梅",
  [":redistribute"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：两名手牌数不同的角色<br/>"..
  "<b>效果</b>：若所有目标角色的手牌数不均相同，手牌数最小的目标角色摸一张牌，不为的弃置一张手牌。"..
  "然后若所有目标角色手牌数相同，你可将以此法弃置的牌交给一名角色。",
}

local enemy_at_the_gates = fk.CreateCard{
  name = "&enemy_at_the_gates",
  skill = "enemy_at_the_gates_skill",
  type = Card.TypeTrick,
}
extension:addCardSpec("enemy_at_the_gates", Card.Spade, 7)
extension:addCardSpec("enemy_at_the_gates", Card.Club, 7)
extension:addCardSpec("enemy_at_the_gates", Card.Club, 13)
Fk:loadTranslationTable{
  ["enemy_at_the_gates"] = "兵临城下",
  [":enemy_at_the_gates"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：一名其他角色<br/>"..
  "<b>效果</b>：你依次亮出牌堆顶四张牌，若为【杀】，你对目标使用之；若不为【杀】，将此牌置入弃牌堆。",
}

local mobile__enemy_at_the_gates = fk.CreateCard{
  name = "&mobile__enemy_at_the_gates",
  type = Card.TypeTrick,
  skill = "mobile__enemy_at_the_gates_skill",
}
extension:addCardSpec("mobile__enemy_at_the_gates", Card.Spade, 7)
extension:addCardSpec("mobile__enemy_at_the_gates", Card.Club, 7)
extension:addCardSpec("mobile__enemy_at_the_gates", Card.Club, 13)
Fk:loadTranslationTable{
  ["mobile__enemy_at_the_gates"] = "兵临城下",
  [":mobile__enemy_at_the_gates"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：一名其他角色<br/>"..
  "<b>效果</b>：你展示牌堆顶的四张牌，依次对目标角色使用其中的【杀】，然后将其余的牌以原顺序放回牌堆顶。",
}

local raid_and_frontal_attack = fk.CreateCard{
  name = "&raid_and_frontal_attack",
  type = Card.TypeTrick,
  is_damage_card = true,
  damage_type = fk.NormalDamage,
  skill = "raid_and_frontal_attack_skill",
}
Fk:loadTranslationTable{
  ["raid_and_frontal_attack"] = "奇正相生",
  [":raid_and_frontal_attack"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：一名其他角色<br/>"..
  "<b>效果</b>：当此牌指定目标后，你为其指定“奇兵”或“正兵”。目标角色可以打出一张【杀】或【闪】，然后若其为："..
  "“奇兵”目标且未打出【杀】，你对其造成1点伤害；“正兵”目标且未打出【闪】，你获得其一张牌。",
}
extension:addCardSpec("raid_and_frontal_attack", Card.Spade, 2)
extension:addCardSpec("raid_and_frontal_attack", Card.Spade, 4)
extension:addCardSpec("raid_and_frontal_attack", Card.Spade, 6)
extension:addCardSpec("raid_and_frontal_attack", Card.Spade, 8)
extension:addCardSpec("raid_and_frontal_attack", Card.Diamond, 3)
extension:addCardSpec("raid_and_frontal_attack", Card.Diamond, 5)
extension:addCardSpec("raid_and_frontal_attack", Card.Diamond, 7)
extension:addCardSpec("raid_and_frontal_attack", Card.Diamond, 9)

local js__peace_spell = fk.CreateCard{
  name = "&js__peace_spell",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeArmor,
  equip_skill = "#js__peace_spell_skill",
}
extension:addCardSpec("js__peace_spell", Card.Heart, 3)
Fk:loadTranslationTable{
  ["js__peace_spell"] = "太平要术",
  [":js__peace_spell"] = "装备牌·防具<br/>"..
  "<b>防具技能</b>：锁定技，防止你受到的属性伤害；你的手牌上限+X（X为存活势力数-1）；当你失去装备区里的【太平要术】后，你摸两张牌，"..
  "然后若你的体力值大于1，则你失去1点体力。",
}

extension:loadCardSkels {
  shade,

  honey_trap,
  daggar_in_smile,
  underhanding,
  redistribute,
  enemy_at_the_gates,
  mobile__enemy_at_the_gates,
  raid_and_frontal_attack,

  js__peace_spell,
}

return extension
