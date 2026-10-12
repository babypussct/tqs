
local extension = Package:new("m_lord_cards", Package.CardPack)
extension.extensionName = "hegemony"
extension:loadSkillSkelsByPath("./packages/hegemony/pkg/m_lord_cards/skills")

Fk:loadTranslationTable{
  ["m_lord_cards"] = "手杀君临天下卡牌",
}

extension.game_modes_whitelist = { "new_heg_mode" }

local liulongcanjia = fk.CreateCard{
  name = "&mobile__liulongcanjia",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeOffensiveRide,
  equip_skill = "#mobile__liulongcanjia_skill",
  ui_name = "-3",
}
extension:addCardSpec("mobile__liulongcanjia", Card.Heart, 13)
Fk:loadTranslationTable{
  ["mobile__liulongcanjia"] = "六龙骖驾",
  [":mobile__liulongcanjia"] = "装备牌·坐骑<br/>"..
  "<b>坐骑技能</b>：锁定技，你与其他角色的距离-3。",
  ["#mobile__liulongcanjia_skill"] = "六龙骖驾",
}

local dragon_phoenix = fk.CreateCard{
  name = "&mobile__dragon_phoenix",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 2,
  equip_skill = "#mobile__dragon_phoenix_skill",
}
extension:addCardSpec("mobile__dragon_phoenix", Card.Spade, 2)
Fk:loadTranslationTable{
  ["mobile__dragon_phoenix"] = "飞龙夺凤",
  [":mobile__dragon_phoenix"] = "装备牌·武器<br/>"..
  "<b>攻击范围</b>：2<br/>"..
  "<b>武器技能</b>：你每回合首次使用【杀】对目标角色造成伤害后，你可以获得其一个“阴阳鱼”标记或一张手牌。",
  ["#mobile__dragon_phoenix_skill"] = "飞龙夺凤",
  ["#mobile__dragon_phoenix-invoke"] = "飞龙夺凤：你可以获得 %dest 一个“阴阳鱼”标记或一张手牌",
}

local luminous_pearl = fk.CreateCard{
  name = "&mobile__luminous_pearl",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
  equip_skill = "#mobile__luminous_pearl_skill",
}
extension:addCardSpec("mobile__luminous_pearl", Card.Diamond, 6)
Fk:loadTranslationTable{
  ["mobile__luminous_pearl"] = "定澜夜明珠",
  [":mobile__luminous_pearl"] = "装备牌·宝物<br/>"..
  "<b>宝物技能</b>：锁定技，你每回合首次弃置牌后，摸一张牌。",
  ["#mobile__luminous_pearl_skill"] = "定澜夜明珠",
}

local grand_ensign = fk.CreateCard{
  name = "&grand_ensign",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeArmor,
  equip_skill = "#grand_ensign_skill",
}
extension:addCardSpec("grand_ensign", Card.Heart, 3)
Fk:loadTranslationTable{
  ["grand_ensign"] = "盟军大纛",
  [":grand_ensign"] = "装备牌·防具<br/>"..
  "<b>防具技能</b>：你受到伤害时，可以弃置两张牌，防止之。",
  ["#grand_ensign_skill"] = "盟军大纛",
  ["#grand_ensign-invoke"] = "盟军大纛：你可以弃置两张牌，防止你受到的伤害",
}

extension:loadCardSkels{
  liulongcanjia,
  dragon_phoenix,
  luminous_pearl,
  grand_ensign,
}

return extension
