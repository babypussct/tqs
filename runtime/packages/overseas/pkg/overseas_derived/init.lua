local extension = Package("overseas_derived", Package.CardPack)
extension.extensionName = "overseas"

extension:loadSkillSkelsByPath("./packages/overseas/pkg/overseas_derived/skills")

Fk:loadTranslationTable{
  ["overseas_derived"] = "国际服衍生牌",
}

local celestialCalabash = fk.CreateCard{
  name = "&celestial_calabash",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 3,
  equip_skill = "#celestial_calabash_skill",
}
extension:addCardSpec("celestial_calabash", Card.Heart, 1)
Fk:loadTranslationTable{
  ["celestial_calabash"] = "灵宝仙葫",
  [":celestial_calabash"] = "装备牌·武器<br /><b>攻击范围</b>：３<br /><b>武器技能</b>："..
    "锁定技，当你造成大于1点的伤害时或一名角色死亡时，你增加1点体力上限并回复1点体力。",
}

local horsetailWhisk = fk.CreateCard{
  name = "&horsetail_whisk",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 5,
  equip_skill = "#horsetail_whisk_skill",
}
extension:addCardSpec("horsetail_whisk", Card.Heart, 1)
Fk:loadTranslationTable{
  ["horsetail_whisk"] = "太极拂尘",
  [":horsetail_whisk"] = "装备牌·武器<br /><b>攻击范围</b>：５<br /><b>武器技能</b>："..
    "当你使用的【杀】指定目标后，目标角色需弃置一张牌，否则不可响应此【杀】；若其弃置的牌与此【杀】花色相同，你获得之。",
}

local talisman = fk.CreateCard{
  name = "&talisman",
  equip_skill = "#talisman_skill",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeArmor,
  on_uninstall = function(self, room, player)
    Armor.onUninstall(self, room, player)
    room:setPlayerMark(player, "@$talisman", 0)
  end,
}
extension:addCardSpec("talisman", Card.Heart, 1)
Fk:loadTranslationTable{
  ["talisman"] = "冲应神符",
  [":talisman"] = "装备牌·防具<br /><b>防具技能</b>：锁定技，①当你受到伤害后，记录造成此伤害的牌的牌名；"..
    "②当你受到伤害时，若造成此伤害的牌的牌名被记录过，此伤害-1。",
}

local moonSpear = fk.CreateCard{
  name = "&moon_spear",
  attack_range = 3,
  equip_skill = "#moon_spear_skill",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
}
extension:addCardSpec("moon_spear", Card.Diamond, 12)
Fk:loadTranslationTable{
  ["moon_spear"] = "银月枪",
  [":moon_spear"] = "装备牌·武器<br /><b>攻击范围</b>：３<br /><b>武器技能</b>：当你于其他角色的回合中首次失去牌后，"..
    "你可使用【杀】。",
}

extension:loadCardSkels{
  celestialCalabash, horsetailWhisk, talisman, moonSpear
}
return extension