-- SPDX-License-Identifier: GPL-3.0-or-later

local extension = Package:new("vanished_dragon_cards", Package.CardPack)
extension.extensionName = "gamemode"
extension.game_modes_whitelist = {
  "vanished_dragon",
}
extension.game_modes_blacklist = {
  "aaa_role_mode",
  "m_1v1_mode",
  "m_1v2_mode",
  "m_2v2_mode",
  "zombie_mode",
  "heg_mode",
}

extension:loadSkillSkelsByPath("./packages/gamemode/pkg/vanished_dragon_cards/skills")

Fk:loadTranslationTable{
  ["vanished_dragon_cards"] = "忠胆英杰",
}

extension:addCardSpec("diversion", Card.Spade, 3)
extension:addCardSpec("diversion", Card.Spade, 4)
extension:addCardSpec("diversion", Card.Spade, 11)
extension:addCardSpec("diversion", Card.Diamond, 3)
extension:addCardSpec("diversion", Card.Diamond, 4)

extension:addCardSpec("paranoid", Card.Spade, 10)
extension:addCardSpec("paranoid", Card.Club, 4)

extension:addCardSpec("reinforcement", Card.Heart, 3)
extension:addCardSpec("reinforcement", Card.Heart, 4)
extension:addCardSpec("reinforcement", Card.Heart, 7)
extension:addCardSpec("reinforcement", Card.Heart, 8)
extension:addCardSpec("reinforcement", Card.Heart, 9)
extension:addCardSpec("reinforcement", Card.Heart, 11)

extension:addCardSpec("abandoning_armor", Card.Club, 12)
extension:addCardSpec("abandoning_armor", Card.Club, 13)

extension:addCardSpec("crafty_escape", Card.Spade, 11)
extension:addCardSpec("crafty_escape", Card.Spade, 13)
extension:addCardSpec("crafty_escape", Card.Heart, 1)
extension:addCardSpec("crafty_escape", Card.Heart, 13)
extension:addCardSpec("crafty_escape", Card.Club, 12)
extension:addCardSpec("crafty_escape", Card.Club, 13)
extension:addCardSpec("crafty_escape", Card.Diamond, 12)

extension:addCardSpec("floating_thunder", Card.Spade, 1)
extension:addCardSpec("floating_thunder", Card.Heart, 12)

extension:addCardSpec("glittery_armor", Card.Spade, 2)
extension:addCardSpec("glittery_armor", Card.Club, 2)

extension:addCardSpec("seven_stars_sword", Card.Spade, 6)

extension:addCardSpec("steel_lance", Card.Spade, 5)

local diversion = fk.CreateCard{
  name = "diversion",
  type = Card.TypeTrick,
  skill = "diversion_skill",
}
Fk:loadTranslationTable{
  ["diversion"] = "声东击西",
  [":diversion"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：距离为1的一名角色<br/>"..
  "<b>效果</b>：你交给目标角色一张手牌并选择另一名其他角色，目标角色将两张牌交给该角色。",

  ["diversion_skill"] = "声东击西",
  ["#diversion_skill"] = "选择一名其他角色，交给其一张牌，令其将两张牌交给你指定的另一名其他角色",
}

local paranoid = fk.CreateCard{
  name = "paranoid",
  type = Card.TypeTrick,
  sub_type = Card.SubtypeDelayedTrick,
  skill = "paranoid_skill",
}
Fk:loadTranslationTable{
  ["paranoid"] = "草木皆兵",
  [":paranoid"] = "延时锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：一名其他角色<br/>"..
  "<b>效果</b>：将【草木皆兵】置于目标角色判定区里。若判定结果不为♣：摸牌阶段，少摸一张牌；摸牌阶段结束时，与其距离为1的角色各摸一张牌。",

  ["paranoid_skill"] = "草木皆兵",
  ["#paranoid_skill"] = "选择一名其他角色，将此牌置于其判定区内。其判定阶段判定：<br/>若结果不为<font color='#CC3131'>♣</font>，"..
  "其摸牌阶段少摸一张牌，与其距离为1的角色各摸一张牌",
}

local reinforcement = fk.CreateCard{
  name = "reinforcement",
  type = Card.TypeTrick,
  skill = "reinforcement_skill",
}
Fk:loadTranslationTable{
  ["reinforcement"] = "增兵减灶",
  [":reinforcement"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：一名角色<br/>"..
  "<b>效果</b>：目标角色摸三张牌，然后选择一项：1.弃置一张非基本牌；2.弃置两张牌。",

  ["reinforcement_skill"] = "增兵减灶",
  ["#reinforcement_skill"] = "选择一名角色，其摸三张牌，然后弃置一张非基本牌或弃置两张牌",
}

local abandoning_armor = fk.CreateCard{
  name = "abandoning_armor",
  type = Card.TypeTrick,
  skill = "abandoning_armor_skill",
}
Fk:loadTranslationTable{
  ["abandoning_armor"] = "弃甲曳兵",
  [":abandoning_armor"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：一名装备区里有牌的其他角色<br/>"..
  "<b>效果</b>：目标角色选择一项：1.弃置手牌区和装备区里所有的武器和进攻坐骑；2.弃置手牌区和装备区里所有的防具和防御坐骑。",

  ["abandoning_armor_skill"] = "弃甲曳兵",
  ["#abandoning_armor_skill"] = "选择一名装备区里有牌的其他角色，其选择弃置所有武器和进攻坐骑，或弃置所有防具和防御坐骑",
}

local crafty_escape = fk.CreateCard{
  name = "crafty_escape",
  type = Card.TypeTrick,
  skill = "crafty_escape_skill",
  is_passive = true,
}
Fk:loadTranslationTable{
  ["crafty_escape"] = "金蝉脱壳",
  [":crafty_escape"] = "锦囊牌<br/>"..
  "<b>时机</b>：当你成为其他角色使用牌的目标时，若你的手牌里只有【金蝉脱壳】<br/>"..
  "<b>目标</b>：该牌<br/>"..
  "<b>效果</b>：令目标牌对你无效，你摸两张牌。<br>当你因弃置而失去【金蝉脱壳】时，你摸一张牌。",

  ["crafty_escape_skill"] = "金蝉脱壳",
}

local floating_thunder = fk.CreateCard{
  name = "floating_thunder",
  type = Card.TypeTrick,
  sub_type = Card.SubtypeDelayedTrick,
  skill = "floating_thunder_skill",
  damage_type = fk.ThunderDamage,
}
Fk:loadTranslationTable{
  ["floating_thunder"] = "浮雷",
  [":floating_thunder"] = "延时锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：你<br/>"..
  "<b>效果</b>：将【浮雷】置于目标角色的判定区里。若判定结果为♠，则目标角色受到X点雷电伤害（X为此牌判定结果为♠的次数）。判定完成后，"..
  "将此牌移动到下家的判定区里。",

  ["floating_thunder_skill"] = "浮雷",
  ["#floating_thunder_skill"] = "将此牌置于你的判定区内。目标角色判定阶段判定：<br/>若结果为♠，其受到雷电伤害。"..
  "判定完成后将【浮雷】移动至其下家判定区内",
}

local glittery_armor = fk.CreateCard{
  name = "glittery_armor",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeArmor,
  equip_skill = "glittery_armor_skill&",
}
Fk:loadTranslationTable{
  ["glittery_armor"] = "烂银甲",
  [":glittery_armor"] = "装备牌·防具<br/>"..
  "<b>防具技能</b>：你可以将一张手牌当【闪】使用或打出。【烂银甲】不会被无效或无视。当你受到【杀】造成的伤害时，你弃置装备区里的【烂银甲】。",
}

local seven_stars_sword = fk.CreateCard{
  name = "seven_stars_sword",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 2,
  equip_skill = "#seven_stars_sword_skill",
}
Fk:loadTranslationTable{
  ["seven_stars_sword"] = "七宝刀",
  [":seven_stars_sword"] = "装备牌·武器<br/>"..
  "<b>攻击范围</b>：2<br/>"..
  "<b>武器技能</b>：锁定技，你使用【杀】无视目标防具，若目标角色未受伤，此【杀】伤害+1。",
}

local steel_lance = fk.CreateCard{
  name = "steel_lance",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 3,
  equip_skill = "#steel_lance_skill",
}
Fk:loadTranslationTable{
  ["steel_lance"] = "衠钢槊",
  [":steel_lance"] = "装备牌·武器<br/>"..
  "<b>攻击范围</b>：3<br/>"..
  "<b>武器技能</b>：当你使用【杀】指定一名角色为目标后，你可以令其弃置你的一张手牌，然后你弃置其一张手牌。",
}

extension:loadCardSkels {
  diversion,
  paranoid,
  reinforcement,
  abandoning_armor,
  crafty_escape,
  floating_thunder,

  glittery_armor,
  seven_stars_sword,
  steel_lance,
}

return extension
