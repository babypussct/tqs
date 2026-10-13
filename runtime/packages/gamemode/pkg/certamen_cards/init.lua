-- SPDX-License-Identifier: GPL-3.0-or-later

local extension = Package:new("certamen_cards", Package.CardPack)
extension.extensionName = "gamemode"

extension:loadSkillSkelsByPath("./packages/gamemode/pkg/certamen_cards/skills")

Fk:loadTranslationTable{
  ["certamen_cards"] = "逐鹿天下",
}

extension:addCardSpec("slash", Card.Spade, 8)
extension:addCardSpec("slash", Card.Spade, 9)
extension:addCardSpec("slash", Card.Spade, 11)
extension:addCardSpec("slash", Card.Club, 11)
extension:addCardSpec("slash", Card.Diamond, 6)
extension:addCardSpec("slash", Card.Diamond, 11)

extension:addCardSpec("thunder__slash", Card.Spade, 4)
extension:addCardSpec("thunder__slash", Card.Club, 4)

extension:addCardSpec("fire__slash", Card.Heart, 3)

extension:addCardSpec("jink", Card.Heart, 4)
extension:addCardSpec("jink", Card.Heart, 8)
extension:addCardSpec("jink", Card.Diamond, 4)
extension:addCardSpec("jink", Card.Diamond, 8)

extension:addCardSpec("peach", Card.Heart, 6)

extension:addCardSpec("analeptic", Card.Club, 6)
extension:addCardSpec("analeptic", Card.Club, 8)

extension:addCardSpec("demobilized", Card.Club, 3)
extension:addCardSpec("demobilized", Card.Diamond, 3)

extension:addCardSpec("borrow_arrows", Card.Spade, 3)
extension:addCardSpec("borrow_arrows", Card.Spade, 6)

extension:addCardSpec("bogus_flower", Card.Heart, 9)
extension:addCardSpec("bogus_flower", Card.Heart, 11)
extension:addCardSpec("bogus_flower", Card.Diamond, 9)

extension:addCardSpec("certamen", Card.Club, 9)

extension:addCardSpec("certamen__broken_halberd", Card.Club, 5)
extension:addCardSpec("dull_blade", Card.Spade, 5)
extension:addCardSpec("yajiao_spear", Card.Diamond, 5)
extension:addCardSpec("bee_armor", Card.Diamond, 10)
extension:addCardSpec("certamen__women_dress", Card.Heart, 10)
extension:addCardSpec("night_cloth", Card.Spade, 10)
extension:addCardSpec("certamen__inferior_horse", Card.Heart, 5)
extension:addCardSpec("brocade_box", Card.Spade, 10)

local demobilized = fk.CreateCard{
  name = "demobilized",
  type = Card.TypeTrick,
  skill = "demobilized_skill",
}
Fk:loadTranslationTable{
  ["demobilized"] = "解甲归田",
  [":demobilized"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：一名装备区内有牌的角色<br/>"..
  "<b>效果</b>：目标获得其装备区内的所有牌。",

  ["demobilized_skill"] = "解甲归田",
  ["#demobilized_skill"] = "选择一名角色，目标角色获得其装备区内的所有牌",
}

local borrow_arrows = fk.CreateCard{
  name = "borrow_arrows",
  type = Card.TypeTrick,
  skill = "borrow_arrows_skill",
  is_passive = true,
}
Fk:loadTranslationTable{
  ["borrow_arrows"] = "草船借箭",
  [":borrow_arrows"] = "锦囊牌<br/>"..
  "<b>时机</b>：【杀】或伤害锦囊牌对你生效前<br/>"..
  "<b>目标</b>：此牌<br/>"..
  "<b>效果</b>：抵消此牌对你产生的效果，此牌结算结束后，你获得之。",
}

local certamen = fk.CreateCard{
  name = "certamen",
  type = Card.TypeTrick,
  skill = "certamen_skill",
  multiple_targets = true,
}
Fk:loadTranslationTable{
  ["certamen"] = "逐鹿天下",
  [":certamen"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：所有角色<br/>"..
  "<b>效果</b>：从牌堆和弃牌堆亮出等同于目标角色数的装备牌，目标角色依次选择其中一张置入其装备区（可替换原装备）。",

  ["certamen_skill"] = "逐鹿天下",
  ["#certamen_skill"] = "亮出等于所有角色数的装备牌，每名角色将其中一张置入装备区",
}

local broken_halberd = fk.CreateCard{
  name = "certamen__broken_halberd",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 0,
  skill = "certamen__equip_skill",
}
Fk:loadTranslationTable{
  ["certamen__broken_halberd"] = "折戟",
  [":certamen__broken_halberd"] = "装备牌·武器<br/>"..
  "<b>攻击范围</b>：0<br/>"..
  "这是一把坏掉的武器……",
}

local dull_blade = fk.CreateCard{
  name = "dull_blade",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 1,
  skill = "certamen__equip_skill",
  equip_skill = "#dull_blade_skill",
}
Fk:loadTranslationTable{
  ["dull_blade"] = "无锋剑",
  [":dull_blade"] = "装备牌·武器<br/>"..
  "<b>攻击范围</b>：1<br/>"..
  "<b>武器技能</b>：锁定技，当你使用【杀】时，你需弃置一张其他牌。",
}

local yajiao_spear = fk.CreateCard{
  name = "yajiao_spear",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 3,
  equip_skill = "#yajiao_spear_skill",
}
Fk:loadTranslationTable{
  ["yajiao_spear"] = "涯角枪",
  [":yajiao_spear"] = "装备牌·武器<br/>"..
  "<b>攻击范围</b>：3<br/>"..
  "<b>武器技能</b>：当你于其他角色回合内首次使用的黑色牌结算结束后，你可以获得之。",
}

local women_dress = fk.CreateCard{
  name = "certamen__women_dress",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeArmor,
  skill = "certamen__equip_skill",
  equip_skill = "#certamen__women_dress_skill",
}
Fk:loadTranslationTable{
  ["certamen__women_dress"] = "女装",
  [":certamen__women_dress"] = "装备牌·防具<br/>"..
  "<b>防具技能</b>：锁定技，当【女装】进入或离开你的装备区后，若你是男性角色，你弃置一张其他牌。",
}

local bee_armor = fk.CreateCard{
  name = "bee_armor",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeArmor,
  skill = "certamen__equip_skill",
  equip_skill = "#bee_armor_skill",
}
Fk:loadTranslationTable{
  ["bee_armor"] = "引蜂甲",
  [":bee_armor"] = "装备牌·防具<br/>"..
  "<b>防具技能</b>：锁定技，当你受到锦囊牌的伤害时，此伤害+1。",
}

local night_cloth = fk.CreateCard{
  name = "night_cloth",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeArmor,
  equip_skill = "#night_cloth_skill",
}
Fk:loadTranslationTable{
  ["night_cloth"] = "夜行衣",
  [":night_cloth"] = "装备牌·防具<br/>"..
  "<b>防具技能</b>：锁定技，你不能成为黑色锦囊牌的目标。",
}

local inferior_horse = fk.CreateCard{
  name = "certamen__inferior_horse",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeOffensiveRide,
  skill = "certamen__equip_skill",
  equip_skill = "#certamen__inferior_horse_skill",
}
Fk:loadTranslationTable{
  ["certamen__inferior_horse"] = "驽马",
  [":certamen__inferior_horse"] = "装备牌·进攻坐骑<br/>"..
  "<b>坐骑技能</b>：锁定技，当【驽马】进入你的装备区后，你弃置装备区里的所有其他牌。",
}

local brocade_box = fk.CreateCard{
  name = "brocade_box",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
  skill = "certamen__equip_skill",
  equip_skill = "brocade_box_skill&",
}
Fk:loadTranslationTable{
  ["brocade_box"] = "锦盒",
  [":brocade_box"] = "装备牌·宝物<br/>"..
  "<b>宝物技能</b>：当一名角色使用【锦盒】后，其观看牌堆顶两张牌，将其中一张扣置于【锦盒】下，称为“礼”。<br>"..
  "出牌阶段，若有“礼”，你可以将“礼”置入弃牌堆，弃置所有和“礼”花色相同的手牌和装备区内的【锦盒】。"..
  "有“礼”的【锦盒】不以此法从装备区置入弃牌堆后，你弃置所有手牌。",
}

extension:loadCardSkels {
  demobilized,
  borrow_arrows,
  certamen,

  broken_halberd,
  dull_blade,
  yajiao_spear,
  bee_armor,
  women_dress,
  night_cloth,
  inferior_horse,
  brocade_box,
}

return extension
