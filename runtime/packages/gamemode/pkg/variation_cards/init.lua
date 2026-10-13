-- SPDX-License-Identifier: GPL-3.0-or-later

local extension = Package:new("variation_cards", Package.CardPack)
extension.extensionName = "gamemode"

extension:loadSkillSkelsByPath("./packages/gamemode/pkg/variation_cards/skills")

Fk:loadTranslationTable{
  ["variation_cards"] = "应变",
}

Fk:addDamageNature(fk.IceDamage, "ice_damage")

extension:addCardSpec("slash", Card.Diamond, 6)
extension:addCardSpec("slash", Card.Diamond, 7)
extension:addCardSpec("slash", Card.Diamond, 9)
extension:addCardSpec("slash", Card.Diamond, 13)
extension:addCardSpec("slash", Card.Heart, 10)
extension:addCardSpec("slash", Card.Heart, 10)
extension:addCardSpec("slash", Card.Heart, 11)
extension:addCardSpec("slash", Card.Club, 6)
extension:addCardSpec("slash", Card.Club, 7)
extension:addCardSpec("slash", Card.Club, 8)
extension:addCardSpec("slash", Card.Club, 11)
extension:addCardSpec("slash", Card.Club, 8)
extension:addCardSpec("slash", Card.Spade, 9, { variation = {"@canqu", "variation_addtarget"} })
extension:addCardSpec("slash", Card.Spade, 9, { variation = {"@canqu", "variation_addtarget"} })
extension:addCardSpec("slash", Card.Spade, 10, { variation = {"@zhuzhan", "variation_addtarget"} })
extension:addCardSpec("slash", Card.Spade, 10)
extension:addCardSpec("slash", Card.Club, 2, { variation = {"@kongchao", "variation_addtarget"} })
extension:addCardSpec("slash", Card.Club, 3, { variation = {"@kongchao", "variation_addtarget"} })
extension:addCardSpec("slash", Card.Club, 4, { variation = {"@kongchao", "variation_addtarget"} })
extension:addCardSpec("slash", Card.Club, 5)
extension:addCardSpec("slash", Card.Club, 11, { variation = {"@canqu", "variation_addtarget"} })
extension:addCardSpec("slash", Card.Diamond, 8, { variation = {"@canqu", "variation_disresponsive"} })

extension:addCardSpec("ice__slash", Card.Spade, 7)
extension:addCardSpec("ice__slash", Card.Spade, 7)
extension:addCardSpec("ice__slash", Card.Spade, 8)
extension:addCardSpec("ice__slash", Card.Spade, 8)
extension:addCardSpec("ice__slash", Card.Spade, 8)

extension:addCardSpec("thunder__slash", Card.Spade, 4)
extension:addCardSpec("thunder__slash", Card.Spade, 5)
extension:addCardSpec("thunder__slash", Card.Spade, 6)
extension:addCardSpec("thunder__slash", Card.Club, 5)
extension:addCardSpec("thunder__slash", Card.Club, 6)
extension:addCardSpec("thunder__slash", Card.Club, 7)
extension:addCardSpec("thunder__slash", Card.Club, 8)
extension:addCardSpec("thunder__slash", Card.Club, 9)
extension:addCardSpec("thunder__slash", Card.Club, 9)
extension:addCardSpec("thunder__slash", Card.Club, 10)
extension:addCardSpec("thunder__slash", Card.Club, 10)

extension:addCardSpec("fire__slash", Card.Heart, 4)
extension:addCardSpec("fire__slash", Card.Heart, 7)
extension:addCardSpec("fire__slash", Card.Diamond, 5)
extension:addCardSpec("fire__slash", Card.Heart, 10, { variation = {"@kongchao", "variation_damage"} })
extension:addCardSpec("fire__slash", Card.Diamond, 4, { variation = {"@kongchao", "variation_damage"} })
extension:addCardSpec("fire__slash", Card.Diamond, 10)

extension:addCardSpec("jink", Card.Diamond, 11)
extension:addCardSpec("jink", Card.Diamond, 3)
extension:addCardSpec("jink", Card.Diamond, 5)
extension:addCardSpec("jink", Card.Diamond, 6)
extension:addCardSpec("jink", Card.Diamond, 7)
extension:addCardSpec("jink", Card.Diamond, 8)
extension:addCardSpec("jink", Card.Diamond, 9)
extension:addCardSpec("jink", Card.Diamond, 10)
extension:addCardSpec("jink", Card.Diamond, 11)
extension:addCardSpec("jink", Card.Heart, 13)
extension:addCardSpec("jink", Card.Heart, 8)
extension:addCardSpec("jink", Card.Heart, 9)
extension:addCardSpec("jink", Card.Heart, 11)
extension:addCardSpec("jink", Card.Heart, 12)
extension:addCardSpec("jink", Card.Diamond, 6)
extension:addCardSpec("jink", Card.Diamond, 7)
extension:addCardSpec("jink", Card.Diamond, 8)
extension:addCardSpec("jink", Card.Diamond, 10)
extension:addCardSpec("jink", Card.Diamond, 11)
extension:addCardSpec("jink", Card.Heart, 2, { variation = {"@kongchao", "variation_draw"} })
extension:addCardSpec("jink", Card.Heart, 2, { variation = {"@kongchao", "variation_draw"} })
extension:addCardSpec("jink", Card.Diamond, 2, { variation = {"@kongchao", "variation_draw"} })
extension:addCardSpec("jink", Card.Diamond, 2, { variation = {"@kongchao", "variation_draw"} })
extension:addCardSpec("jink", Card.Diamond, 4, { variation = {"@canqu", "variation_cancel"} })

extension:addCardSpec("peach", Card.Diamond, 12)
extension:addCardSpec("peach", Card.Heart, 3)
extension:addCardSpec("peach", Card.Heart, 4)
extension:addCardSpec("peach", Card.Heart, 6)
extension:addCardSpec("peach", Card.Heart, 7)
extension:addCardSpec("peach", Card.Heart, 8)
extension:addCardSpec("peach", Card.Heart, 9)
extension:addCardSpec("peach", Card.Heart, 12)
extension:addCardSpec("peach", Card.Heart, 5)
extension:addCardSpec("peach", Card.Heart, 6)
extension:addCardSpec("peach", Card.Diamond, 2)
extension:addCardSpec("peach", Card.Diamond, 3)

extension:addCardSpec("analeptic", Card.Diamond, 9)
extension:addCardSpec("analeptic", Card.Spade, 3)
extension:addCardSpec("analeptic", Card.Spade, 9)
extension:addCardSpec("analeptic", Card.Club, 3)
extension:addCardSpec("analeptic", Card.Club, 9)

extension:addCardSpec("snatch", Card.Diamond, 3)
extension:addCardSpec("snatch", Card.Diamond, 4)
extension:addCardSpec("snatch", Card.Spade, 11)

extension:addCardSpec("dismantlement", Card.Heart, 12)
extension:addCardSpec("dismantlement", Card.Spade, 4)
extension:addCardSpec("dismantlement", Card.Heart, 2)

extension:addCardSpec("amazing_grace", Card.Heart, 3)
extension:addCardSpec("amazing_grace", Card.Heart, 4)

extension:addCardSpec("duel", Card.Diamond, 1)
extension:addCardSpec("duel", Card.Spade, 1)
extension:addCardSpec("duel", Card.Club, 1)

extension:addCardSpec("savage_assault", Card.Spade, 13, { variation = {"@fujia", "variation_minustarget"} })
extension:addCardSpec("savage_assault", Card.Spade, 7, { variation = {"@fujia", "variation_minustarget"} })
extension:addCardSpec("savage_assault", Card.Club, 7, { variation = {"@fujia", "variation_minustarget"} })

extension:addCardSpec("archery_attack", Card.Heart, 1, { variation = {"@fujia", "variation_minustarget"} })

extension:addCardSpec("lightning", Card.Heart, 12)

extension:addCardSpec("god_salvation", Card.Heart, 1, { variation = {"@fujia", "variation_minustarget"} })

extension:addCardSpec("nullification", Card.Club, 12)
extension:addCardSpec("nullification", Card.Club, 13, { variation = {"@canqu", "variation_draw"} })
extension:addCardSpec("nullification", Card.Spade, 11)
extension:addCardSpec("nullification", Card.Diamond, 12)
extension:addCardSpec("nullification", Card.Heart, 1)
extension:addCardSpec("nullification", Card.Spade, 13, { variation = {"@kongchao", "variation_draw"} })
extension:addCardSpec("nullification", Card.Heart, 13, { variation = {"@kongchao", "variation_cancel"} })

extension:addCardSpec("indulgence", Card.Heart, 6)
extension:addCardSpec("indulgence", Card.Club, 6)
extension:addCardSpec("indulgence", Card.Spade, 6)

extension:addCardSpec("iron_chain", Card.Spade, 11)
extension:addCardSpec("iron_chain", Card.Spade, 12)
extension:addCardSpec("iron_chain", Card.Club, 10)
extension:addCardSpec("iron_chain", Card.Club, 11)
extension:addCardSpec("iron_chain", Card.Club, 12)
extension:addCardSpec("iron_chain", Card.Club, 13)

extension:addCardSpec("supply_shortage", Card.Spade, 10)
extension:addCardSpec("supply_shortage", Card.Club, 4)

extension:addCardSpec("drowning", Card.Spade, 3, { variation = {"@zhuzhan", "variation_addtarget"} })
extension:addCardSpec("drowning", Card.Spade, 4, { variation = {"@zhuzhan", "variation_addtarget"} })

extension:addCardSpec("unexpectation", Card.Heart, 3)
extension:addCardSpec("unexpectation", Card.Diamond, 11)

extension:addCardSpec("adaptation", Card.Spade, 2)

extension:addCardSpec("foresight", Card.Heart, 7)
extension:addCardSpec("foresight", Card.Heart, 8)
extension:addCardSpec("foresight", Card.Heart, 9)
extension:addCardSpec("foresight", Card.Heart, 11)

extension:addCardSpec("chasing_near", Card.Spade, 3)
extension:addCardSpec("chasing_near", Card.Spade, 12, { variation = {"@fujia", "variation_disresponsive"} })
extension:addCardSpec("chasing_near", Card.Club, 3, { variation = {"@zhuzhan", "variation_addtarget"} })
extension:addCardSpec("chasing_near", Card.Club, 4, { variation = {"@zhuzhan", "variation_addtarget"} })

extension:addCardSpec("crossbow", Card.Diamond, 1)
extension:addCardSpec("crossbow", Card.Club, 1)
extension:addCardSpec("double_swords", Card.Spade, 2)
extension:addCardSpec("qinggang_sword", Card.Spade, 6)
extension:addCardSpec("blade", Card.Spade, 5)
extension:addCardSpec("spear", Card.Spade, 12)
extension:addCardSpec("axe", Card.Diamond, 5)
extension:addCardSpec("kylin_bow", Card.Heart, 5)
extension:addCardSpec("guding_blade", Card.Spade, 1)

extension:addCardSpec("black_chain", Card.Diamond, 12)
extension:addCardSpec("five_elements_fan", Card.Diamond, 1)

extension:addCardSpec("eight_diagram", Card.Spade, 2)
extension:addCardSpec("nioh_shield", Card.Club, 2)
extension:addCardSpec("vine", Card.Spade, 2)
extension:addCardSpec("vine", Card.Club, 2)

extension:addCardSpec("breastplate", Card.Club, 1)
extension:addCardSpec("dark_armor", Card.Club, 2)
extension:addCardSpec("wonder_map", Card.Club, 12)
extension:addCardSpec("taigong_tactics", Card.Spade, 1)
extension:addCardSpec("bronze_sparrow", Card.Club, 13)

extension:addCardSpec("chitu", Card.Heart, 5)
extension:addCardSpec("zixing", Card.Diamond, 13)
extension:addCardSpec("dayuan", Card.Spade, 13)
extension:addCardSpec("jueying", Card.Spade, 5)
extension:addCardSpec("dilu", Card.Club, 5)
extension:addCardSpec("zhuahuangfeidian", Card.Heart, 13)
extension:addCardSpec("hualiu", Card.Diamond, 13)

local ice__slash = fk.CreateCard{
  name = "ice__slash",
  type = Card.TypeBasic,
  skill = "ice__slash_skill",
  is_damage_card = true,
  damage_type = fk.IceDamage,
}
Fk:loadTranslationTable{
  ["ice__slash"] = "冰杀",
  [":ice__slash"] = "基本牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：攻击范围内的一名角色<br/>"..
  "<b>效果</b>：对目标角色造成1点冰冻伤害。<br/>"..
  "（一名角色造成不为连环伤害的冰冻伤害时，若受到此伤害的角色有牌，来源可防止此伤害，然后依次弃置其两张牌）。",

  ["ice__slash_skill"] = "冰杀",
  ["#ice__slash_skill"] = "选择攻击范围内的一名角色，对其造成1点冰冻伤害",
  ["#ice__slash_skill_multi"] = "选择攻击范围内的至多%arg名角色，对这些角色各造成1点冰冻伤害",
}

local drowning = fk.CreateCard{
  name = "drowning",
  type = Card.TypeTrick,
  skill = "drowning_skill",
  is_damage_card = true,
  damage_type = fk.ThunderDamage,
}
Fk:loadTranslationTable{
  ["drowning"] = "水淹七军",
  [":drowning"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：一名装备区里有牌的其他角色<br/>"..
  "<b>效果</b>：目标角色选择一项：1.弃置装备区所有牌；2.你对其造成1点雷电伤害。",

  ["drowning_skill"] = "水淹七军",
  ["#drowning_skill"] = "选择一名装备区有牌的其他角色，其选择弃置装备区所有牌或你对其造成1点雷电伤害",
}

local unexpectation = fk.CreateCard{
  name = "unexpectation",
  type = Card.TypeTrick,
  skill = "unexpectation_skill",
  is_damage_card = true,
  damage_type = fk.NormalDamage,
}
Fk:loadTranslationTable{
  ["unexpectation"] = "出其不意",
  [":unexpectation"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：一名有手牌的其他角色<br/>"..
  "<b>效果</b>：你展示目标角色的一张手牌，若该牌与此【出其不意】花色不同，你对其造成1点伤害。",

  ["unexpectation_skill"] = "出其不意",
  ["#unexpectation_skill"] = "选择一名有手牌的其他角色，展示其一张手牌，若花色与此牌不同则对其造成伤害",
}

local adaptation = fk.CreateCard{
  name = "adaptation",
  type = Card.TypeTrick,
  skill = "adaptation_skill",
  is_passive = true,
}
Fk:loadTranslationTable{
  ["adaptation"] = "随机应变",
  [":adaptation"] = "锦囊牌<br/>"..
  "<b>效果</b>：此牌视为你本回合使用或打出的上一张基本牌或普通锦囊牌。",
  ["adaptation_skill"] = "随机应变",
}

local foresight = fk.CreateCard{
  name = "foresight",
  type = Card.TypeTrick,
  skill = "foresight_skill",
}
Fk:loadTranslationTable{
  ["foresight"] = "洞烛先机",
  [":foresight"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：你<br/>"..
  "<b>效果</b>：目标角色卜算2（观看牌堆顶的两张牌，将其中任意张以任意顺序置于牌堆顶，其余以任意顺序置于牌堆底），然后摸两张牌。",

  ["foresight_skill"] = "洞烛先机",
  ["#foresight_skill"] = "观看牌堆顶两张牌，以任意顺序置于牌堆顶或牌堆底，然后摸两张牌",
}

local chasing_near = fk.CreateCard{
  name = "chasing_near",
  type = Card.TypeTrick,
  skill = "chasing_near_skill",
}
Fk:loadTranslationTable{
  ["chasing_near"] = "逐近弃远",
  [":chasing_near"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：一名区域里有牌的其他角色<br/>"..
  "<b>效果</b>：若你与目标角色距离为1，你获得其区域里一张牌；若你与目标角色距离大于1，你弃置其区域里一张牌。",

  ["chasing_near_skill"] = "逐近弃远",
  ["#chasing_near_skill"] = "选择一名区域里有牌的其他角色，若距离为1则获得其区域里一张牌，若距离大于1则弃置其区域里一张牌",
}

local black_chain = fk.CreateCard{
  name = "black_chain",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 3,
  equip_skill = "#black_chain_skill",
}
Fk:loadTranslationTable{
  ["black_chain"] = "乌铁锁链",
  [":black_chain"] = "装备牌·武器<br/>"..
  "<b>攻击范围</b>：3<br/>"..
  "<b>武器技能</b>：当你使用【杀】指定目标后，横置目标角色的武将牌。",
}

local five_elements_fan = fk.CreateCard{
  name = "five_elements_fan",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 4,
  equip_skill = "#five_elements_fan_skill",
}
Fk:loadTranslationTable{
  ["five_elements_fan"] = "五行鹤翎扇",
  [":five_elements_fan"] = "装备牌·武器<br/>"..
  "<b>攻击范围</b>：4<br/>"..
  "<b>武器技能</b>：当你声明使用非普通【杀】后，你可以将此【杀】改为雷【杀】、火【杀】、冰【杀】或任意其他非普通【杀】。",
}

local breastplate = fk.CreateCard{
  name = "breastplate",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeArmor,
  equip_skill = "#breastplate_skill",
  special_skills = {"#put_equip"},
}
Fk:loadTranslationTable{
  ["breastplate"] = "护心镜",
  [":breastplate"] = "装备牌·防具<br/>"..
  "<b>防具技能</b>：当你受到大于1点的伤害或致命伤害时，你可以将装备区里的【护心镜】置入弃牌堆，防止此伤害。",
}

local dark_armor = fk.CreateCard{
  name = "dark_armor",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeArmor,
  equip_skill = "#dark_armor_skill",
}
Fk:loadTranslationTable{
  ["dark_armor"] = "黑光铠",
  [":dark_armor"] = "装备牌·防具<br/>"..
  "<b>防具技能</b>：当你成为【杀】、伤害锦囊或黑色锦囊牌的目标后，若你不是唯一目标，此牌对你无效。",
}

local wonder_map = fk.CreateCard{
  name = "wonder_map",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
  equip_skill = "#wonder_map_skill",
}
Fk:loadTranslationTable{
  ["wonder_map"] = "天机图",
  [":wonder_map"] = "装备牌·宝物<br/>"..
  "<b>宝物技能</b>：锁定技，此牌进入你的装备区时，弃置一张其他牌；此牌离开你的装备区时，你将手牌摸至五张。",
}

local taigong_tactics = fk.CreateCard{
  name = "taigong_tactics",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
  equip_skill = "#taigong_tactics_skill",
}
Fk:loadTranslationTable{
  ["taigong_tactics"] = "太公阴符",
  [":taigong_tactics"] = "装备牌·宝物<br/>"..
  "<b>宝物技能</b>：出牌阶段开始时，你可以横置或重置一名角色；出牌阶段结束时，你可以重铸一张手牌。",
}

local bronze_sparrow = fk.CreateCard{
  name = "bronze_sparrow",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
  equip_skill = "#bronze_sparrow_skill",
}
Fk:loadTranslationTable{
  ["bronze_sparrow"] = "铜雀",
  [":bronze_sparrow"] = "装备牌·宝物<br/>"..
  "<b>宝物技能</b>：锁定技，你每回合首次使用具有应变效果的牌无需强化条件直接发动应变效果。",
}

extension:loadCardSkels {
  ice__slash,

  drowning,
  unexpectation,
  adaptation,
  foresight,
  chasing_near,

  black_chain,
  five_elements_fan,
  breastplate,
  dark_armor,
  wonder_map,
  taigong_tactics,
  bronze_sparrow,
}

return extension
