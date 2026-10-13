-- SPDX-Lstabnse-Identifier: GPL-3.0-or-later

local extension = Package:new("espionage_cards", Package.CardPack)
extension.extensionName = "gamemode"

extension:loadSkillSkelsByPath("./packages/gamemode/pkg/espionage_cards/skills")

Fk:loadTranslationTable{
  ["espionage_cards"] = "用间",
}
extension:addCardSpec("slash", Card.Heart, 5, { presentcard = 1 })
extension:addCardSpec("slash", Card.Heart, 10, { presentcard = 1 })
extension:addCardSpec("slash", Card.Heart, 11, { presentcard = 1 })
extension:addCardSpec("slash", Card.Heart, 12, { presentcard = 1 })

extension:addCardSpec("stab__slash", Card.Spade, 6)
extension:addCardSpec("stab__slash", Card.Spade, 7)
extension:addCardSpec("stab__slash", Card.Spade, 8)
extension:addCardSpec("stab__slash", Card.Club, 2)
extension:addCardSpec("stab__slash", Card.Club, 6)
extension:addCardSpec("stab__slash", Card.Club, 7)
extension:addCardSpec("stab__slash", Card.Club, 8)
extension:addCardSpec("stab__slash", Card.Club, 9)
extension:addCardSpec("stab__slash", Card.Club, 10)
extension:addCardSpec("stab__slash", Card.Diamond, 13)

extension:addCardSpec("jink", Card.Heart, 2, { presentcard = 1 })
extension:addCardSpec("jink", Card.Diamond, 2, { presentcard = 1 })
extension:addCardSpec("jink", Card.Diamond, 5)
extension:addCardSpec("jink", Card.Diamond, 6)
extension:addCardSpec("jink", Card.Diamond, 7)
extension:addCardSpec("jink", Card.Diamond, 8)
extension:addCardSpec("jink", Card.Diamond, 12)

extension:addCardSpec("peach", Card.Heart, 7)
extension:addCardSpec("peach", Card.Heart, 8)
extension:addCardSpec("peach", Card.Diamond, 11, { presentcard = 1 })

extension:addCardSpec("es__poison", Card.Spade, 4, { presentcard = 1 })
extension:addCardSpec("es__poison", Card.Spade, 5, { presentcard = 1 })
extension:addCardSpec("es__poison", Card.Spade, 9, { presentcard = 1 })
extension:addCardSpec("es__poison", Card.Spade, 10, { presentcard = 1 })
extension:addCardSpec("es__poison", Card.Club, 4)


extension:addCardSpec("snatch", Card.Spade, 3, { presentcard = 1 })
extension:addCardSpec("duel", Card.Diamond, 1, { presentcard = 1 })
extension:addCardSpec("nullification", Card.Spade, 11)
extension:addCardSpec("nullification", Card.Club, 11)
extension:addCardSpec("nullification", Card.Club, 12)
extension:addCardSpec("amazing_grace", Card.Heart, 3, { presentcard = 1 })

extension:addCardSpec("bogus_flower", Card.Diamond, 3, { presentcard = 1 })
extension:addCardSpec("bogus_flower", Card.Diamond, 4, { presentcard = 1 })
extension:addCardSpec("scrape_poison", Card.Spade, 1)
extension:addCardSpec("scrape_poison", Card.Heart, 1)
extension:addCardSpec("sincere_treat", Card.Diamond, 9)
extension:addCardSpec("sincere_treat", Card.Diamond, 10)
extension:addCardSpec("looting", Card.Spade, 12)
extension:addCardSpec("looting", Card.Spade, 13)
extension:addCardSpec("looting", Card.Heart, 6)

extension:addCardSpec("broken_halberd", Card.Club, 1, { presentcard = 1 })
extension:addCardSpec("seven_stars_precious_sword", Card.Spade, 2, { presentcard = 1 })
extension:addCardSpec("yitian_sword", Card.Club, 5)
extension:addCardSpec("bee_cloth", Card.Club, 3, { presentcard = 1 })
extension:addCardSpec("women_dress", Card.Heart, 9, { presentcard = 1 })
extension:addCardSpec("elephant", Card.Heart, 13, { presentcard = 1 })
extension:addCardSpec("inferior_horse", Card.Club, 13, { presentcard = 1 })
extension:addCardSpec("carrier_pigeon", Card.Heart, 4, { presentcard = 1 })

local stab__slash = fk.CreateCard{
  name = "stab__slash",
  type = Card.TypeBasic,
  skill = "stab__slash_skill",
  is_damage_card = true,
  damage_type = fk.NormalDamage,
}
Fk:loadTranslationTable{
  ["stab__slash"] = "刺杀",
  [":stab__slash"] = "基本牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：攻击范围内的一名角色<br/>"..
  "<b>效果</b>：对目标角色造成1点伤害。当目标角色使用【闪】抵消刺【杀】时，若其有手牌，其需弃置一张手牌，否则此刺【杀】依然造成伤害。",

  ["stab__slash_skill"] = "刺杀",
}

local es__poison = fk.CreateCard{
  name = "es__poison",
  type = Card.TypeBasic,
  skill = "es__poison_skill",
  is_passive = true,
}
Fk:loadTranslationTable{
  ["es__poison"] = "毒",
  [":es__poison"] = "基本牌<br/>"..
  "<b>效果</b>：当【毒】正面向上离开你的手牌区或作为你的拼点牌亮出后，你失去1点体力。<br>"..
  "当你因摸牌获得【毒】后，你可以将之交给一名其他角色，以此法失去【毒】时不触发失去体力效果。",

  ["es__poison_skill"] = "毒",
}

local bogus_flower = fk.CreateCard{
  name = "bogus_flower",
  type = Card.TypeTrick,
  skill = "bogus_flower_skill",
}
Fk:loadTranslationTable{
  ["bogus_flower"] = "树上开花",
  [":bogus_flower"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：你<br/>"..
  "<b>效果</b>：目标角色弃置至多两张牌，然后摸等量的牌；若弃置了装备牌，则多摸一张牌。",

  ["bogus_flower_skill"] = "树上开花",
  ["#bogus_flower_skill"] = "对你使用，弃置至多两张牌并摸等量的牌，若弃置了装备牌则多摸一张牌",
}

local scrape_poison = fk.CreateCard{
  name = "scrape_poison",
  type = Card.TypeTrick,
  skill = "scrape_poison_skill",
}
Fk:loadTranslationTable{
  ["scrape_poison"] = "刮骨疗毒",
  [":scrape_poison"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：一名已受伤角色<br/>"..
  "<b>效果</b>：目标角色回复1点体力，然后其可以弃置一张【毒】，以此法失去【毒】时不触发失去体力效果。",

  ["scrape_poison_skill"] = "刮骨疗毒",
  ["#scrape_poison_skill"] = "选择一名已受伤角色，其回复1点体力，然后可以弃置一张【毒】",
}

local sincere_treat = fk.CreateCard{
  name = "sincere_treat",
  type = Card.TypeTrick,
  skill = "sincere_treat_skill",
}
Fk:loadTranslationTable{
  ["sincere_treat"] = "推心置腹",
  [":sincere_treat"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：距离为1的一名区域内有牌的其他角色<br/>"..
  "<b>效果</b>：你获得目标角色区域里至多两张牌，然后交给其等量的手牌。",

  ["sincere_treat_skill"] = "推心置腹",
  ["#sincere_treat_skill"] = "选择距离为1的一名角色，获得其区域里至多两张牌，然后交给其等量的手牌",
}

local looting = fk.CreateCard{
  name = "looting",
  type = Card.TypeTrick,
  skill = "looting_skill",
  is_damage_card = true,
  damage_type = fk.NormalDamage,
}
Fk:loadTranslationTable{
  ["looting"] = "趁火打劫",
  [":looting"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：一名有手牌的其他角色<br/>"..
  "<b>效果</b>：你展示目标角色一张手牌，然后令其选择一项：将此牌交给你，或受到你造成的1点伤害。",

  ["looting_skill"] = "趁火打劫",
  ["#looting_skill"] = "选择一名有手牌的其他角色，展示其一张手牌，其选择将此牌交给你或受到你造成的1点伤害",
}

local broken_halberd = fk.CreateCard{
  name = "broken_halberd",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 0,
  dynamic_equip_skills = function (self, player)
    if (Fk:currentRoom():getBanner("huaxiu") or {})[self.name] then
      return { Fk.skills["#soul__crossbow_skill"] }
    end
  end,
  dynamic_attack_range = function(self, player)
    if (Fk:currentRoom():getBanner("huaxiu") or {})[self.name] then
      return 1
    end
  end,
  dynamic_desc = function (self, player, lang)
    if (Fk:currentRoom():getBanner("huaxiu") or {})[self.name] then
      return Fk:translate(":soul__crossbow")
    end
  end,
}
Fk:loadTranslationTable{
  ["broken_halberd"] = "折戟",
  [":broken_halberd"] = "装备牌·武器<br/>"..
  "<b>攻击范围</b>：0<br/>"..
  "这是一把坏掉的武器……",
}

local seven_stars_precious_sword = fk.CreateCard{
  name = "seven_stars_precious_sword",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 2,
  equip_skill = "#seven_stars_precious_sword_skill",
}
Fk:loadTranslationTable{
  ["seven_stars_precious_sword"] = "七星宝刀",
  [":seven_stars_precious_sword"] = "装备牌·武器<br/>"..
  "<b>攻击范围</b>：2<br/>"..
  "<b>武器技能</b>：锁定技，当此牌进入你的装备区时，弃置你判定区和装备区内除此牌外所有的牌。",
}

local yitian_sword = fk.CreateCard{
  name = "yitian_sword",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 2,
  equip_skill = "#yitian_sword_skill",
}
Fk:loadTranslationTable{
  ["yitian_sword"] = "倚天剑",
  [":yitian_sword"] = "装备牌·武器<br/>"..
  "<b>攻击范围</b>：2<br/>"..
  "<b>武器技能</b>：当你使用【杀】造成伤害后，你可以弃置一张手牌，然后回复1点体力。",
}

local bee_cloth = fk.CreateCard{
  name = "bee_cloth",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeArmor,
  equip_skill = "#bee_cloth_skill",
}
Fk:loadTranslationTable{
  ["bee_cloth"] = "引蜂衣",
  [":bee_cloth"] = "装备牌·防具<br/>"..
  "<b>防具技能</b>：锁定技，你受到锦囊牌的伤害+1，因【毒】的效果失去体力+1。",
}

local women_dress = fk.CreateCard{
  name = "women_dress",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeArmor,
  equip_skill = "#women_dress_skill",
  dynamic_equip_skills = function (self, player)
    if (Fk:currentRoom():getBanner("huaxiu") or {})[self.name] then
      return { Fk.skills["#soul__eight_diagram_skill"] }
    end
  end,
  dynamic_desc = function (self, player, lang)
    if (Fk:currentRoom():getBanner("huaxiu") or {})[self.name] then
      return Fk:translate(":soul__eight_diagram")
    end
  end,
}
Fk:loadTranslationTable{
  ["women_dress"] = "女装",
  [":women_dress"] = "装备牌·防具<br/>"..
  "<b>防具技能</b>：锁定技，若你是男性角色，当你成为【杀】的目标后，你判定，若结果为黑色，此【杀】伤害+1。",
}

local elephant = fk.CreateCard{
  name = "elephant",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeDefensiveRide,
  equip_skill = "#elephant_skill",
}
Fk:loadTranslationTable{
  ["elephant"] = "战象",
  [":elephant"] = "装备牌·坐骑<br/>"..
  "<b>坐骑技能</b>：锁定技，其他角色计算至你的距离+1，其他角色对你赠予时赠予失败。",
}

local inferior_horse = fk.CreateCard{
  name = "inferior_horse",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeOffensiveRide,
  equip_skill = "#inferior_horse_skill",
  dynamic_equip_skills = function (self, player)
    if (Fk:currentRoom():getBanner("huaxiu") or {})[self.name] then
      return { Fk.skills["#lingling_horse_skill"] }
    end
  end,
  dynamic_desc = function (self, player, lang)
    if (Fk:currentRoom():getBanner("huaxiu") or {})[self.name] then
      return Fk:translate(":lingling_horse")
    end
  end,
}
Fk:loadTranslationTable{
  ["inferior_horse"] = "驽马",
  [":inferior_horse"] = "装备牌·坐骑<br/>"..
  "<b>坐骑技能</b>：锁定技，你计算至其他角色的距离-1，其他角色计算至你的距离始终为1。",
}

local carrier_pigeon = fk.CreateCard{
  name = "carrier_pigeon",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
  equip_skill = "carrier_pigeon_skill&",
}
Fk:loadTranslationTable{
  ["carrier_pigeon"] = "信鸽",
  [":carrier_pigeon"] = "装备牌·宝物<br/>"..
  "<b>宝物技能</b>：出牌阶段限一次，你可以将一张手牌交给一名其他角色。",
}

extension:loadCardSkels {
  stab__slash,
  es__poison,

  bogus_flower,
  scrape_poison,
  sincere_treat,
  looting,

  broken_halberd,
  seven_stars_precious_sword,
  yitian_sword,
  bee_cloth,
  women_dress,
  elephant,
  inferior_horse,
  carrier_pigeon,
}

return extension
