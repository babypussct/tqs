local extension = Package:new("lord_cards", Package.CardPack)
extension.extensionName = "hegemony"
extension:loadSkillSkelsByPath("./packages/hegemony/pkg/lord_cards/skills")

Fk:loadTranslationTable{
  ["lord_cards"] = "君临天下卡牌",
}

extension.game_modes_whitelist = { "new_heg_mode" }

local H = require "packages.hegemony.util"

local dragon_phoenix = fk.CreateCard{
  name = "dragon_phoenix",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 2,
  equip_skill = "#dragon_phoenix_skill",
}
H.addCardToConvertCards("dragon_phoenix", "double_swords")
extension:addCardSpec("dragon_phoenix", Card.Spade, 2)
Fk:loadTranslationTable{
  ["dragon_phoenix"] = "飞龙夺凤",
  [":dragon_phoenix"] = "装备牌·武器<br/>"..
  "<b>攻击范围</b>：2<br/>"..
  "<b>武器技能</b>：当你使用【杀】指定目标后，你可以令目标弃置一张牌。"..
  "当你使用【杀】造成伤害使目标进入濒死状态后，你可以获得其一张手牌。",
}

local peace_spell = fk.CreateCard{
  name = "peace_spell",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeArmor,
  equip_skill = "#peace_spell_skill",
}
H.addCardToConvertCards("peace_spell", "jingfan")
extension:addCardSpec("peace_spell", Card.Heart, 3)
Fk:loadTranslationTable{
  ["peace_spell"] = "太平要术",
  [":peace_spell"] = "装备牌·防具<br/>"..
  "<b>防具技能</b>：锁定技，当你受到属性伤害时，防止此伤害。你的手牌上限+X（X为与你势力相同的角色数）。"..
  "当你失去装备区里的【太平要术】后，你摸两张牌，然后若你的体力值大于1，你失去1点体力。",
  ["#peace_spell_skill"] = "太平要术",
}

local luminous_pearl = fk.CreateCard{
  name = "luminous_pearl",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
  equip_skill = "luminous_pearl_skill",
  on_install = function(self, room, player)
    Treasure.onInstall(self, room, player)
    if (player:hasSkill("hs__zhiheng") or player:hasSkill("lord__zhiheng") or player:hasSkill("wk_heg__zhiheng")) then
      room:handleAddLoseSkills(player, "-luminous_pearl_skill", nil, false, true)
    end
  end,
}
H.addCardToConvertCards("luminous_pearl", "six_swords")
extension:addCardSpec("luminous_pearl", Card.Diamond, 6)
Fk:loadTranslationTable{
  ["luminous_pearl"] = "定澜夜明珠",
  [":luminous_pearl"] = "装备牌·宝物<br/>"..
  "<b>宝物技能</b>：锁定技，若你没有〖制衡〗，你视为拥有〖制衡〗；若你有〖制衡〗，取消〖制衡〗的数量限制。",
}

local liulongcanjia = fk.CreateCard{
  name = "liulongcanjia",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeDefensiveRide,
  equip_skill = "#liulongcanjia_skill",
  ui_name = "±1",

  on_install = function(self, room, player)
    local cards = player:getEquipments(Card.SubtypeOffensiveRide)
    if #cards > 0 then room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name, nil, true, player.id) end
    DefensiveRide.onInstall(self, room, player)
    room:setPlayerMark(player, "@@liulongcanjia", 1) -- 绷
  end,
  on_uninstall = function(self, room, player)
    DefensiveRide.onUninstall(self, room, player)
    room:setPlayerMark(player, "@@liulongcanjia", 0)
  end,
}
H.addCardToConvertCards("liulongcanjia", "zhuahuangfeidian")
extension:addCardSpec("liulongcanjia", Card.Heart, 13)
Fk:loadTranslationTable{
  ["liulongcanjia"] = "六龙骖驾",
  [":liulongcanjia"] = "装备牌·坐骑<br/>"..
  "<b>坐骑技能</b>：锁定技，其他角色与你的距离+1，你与其他角色的距离-1；"..
  "当【六龙骖驾】移至你的装备区后，你将你的装备区里所有其他坐骑牌置入弃牌堆；你不能使用坐骑牌。",
}

local scaly_wings = fk.CreateCard{
  name = "scaly_wings",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 0,
  equip_skill = "#scaly_wings_skill",
}
H.addCardToConvertCards("scaly_wings", "qinggang_sword")
extension:addCardSpec("scaly_wings", Card.Spade, 6)
Fk:loadTranslationTable{
  ["scaly_wings"] = "戢鳞潜翼",
  [":scaly_wings"] = "装备牌·武器<br/>"..
  "<b>攻击范围</b>：X <br/>"..
  "<b>武器技能</b>：锁定技，此牌的攻击范围为你已损失的体力值；"..
  "当你使用【杀】指定目标后，你令你攻击范围内不为此【杀】目标的角色不能使用牌直至此【杀】结算后。",
}

--[[
local command_world = fk.CreateCard{
  name = "&command_world",
  type = Card.TypeTrick,
  skill = "command_world_skill",
}
extension:addCardSpec("command_world", Card.Spade, 12)
Fk:loadTranslationTable{
  ["command_world"] = "号令天下",
  [":command_world"] = "锦囊牌·<font color='blue'>魏</font><br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：体力值不是最少的一名角色<br/>"..
  "<b>效果</b>：除目标角色外的每名角色依次可以选择一项：1.弃置一张手牌，视为对其使用一张【杀】；2.弃置其一张牌。<br>"..
  "魏：魏势力角色选择1时无需弃牌，选择2时可以获得弃置其的牌。",

  ["command_world_skill"] = "号令天下",
  ["#command_world_skill"] = "选择一名角色，目标以外的角色可以视为对其使用【杀】或弃置其牌",
}

local restore_heartland = fk.CreateCard{
  name = "&restore_heartland",
  type = Card.TypeTrick,
  skill = "restore_heartland_skill",
}
extension:addCardSpec("restore_heartland", Card.Diamond, 1)
Fk:loadTranslationTable{
  ["restore_heartland"] = "克复中原",
  [":restore_heartland"] = "锦囊牌·<font color='red'>蜀</font><br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：任意名角色<br/>"..
  "<b>效果</b>：目标角色依次选择一项：1.视为使用一张【杀】；2.摸一张牌。<br>"..
  "蜀：蜀势力角色选择1时此【杀】伤害+1，选择2时改为摸两张牌。",

  ["restore_heartland_skill"] = "克复中原",
  ["#restore_heartland_skill"] = "令任意名角色选择视为使用【杀】或摸一张牌",
}

local strengthen_state = fk.CreateCard{
  name = "&strengthen_state",
  type = Card.TypeTrick,
  skill = "strengthen_state_skill",
}
extension:addCardSpec("strengthen_state", Card.Heart, 1)
Fk:loadTranslationTable{
  ["strengthen_state"] = "固国安邦",
  [":strengthen_state"] = "锦囊牌·<font color='green'>吴</font><br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：你<br/>"..
  "<b>效果</b>：摸八张牌，然后弃置至少六张手牌。<br>"..
  "吴：你可以将弃置的牌交给吴势力角色，每名角色至多两张。",

  ["strengthen_state_skill"] = "固国安邦",
  ["#strengthen_state_skill"] = "摸八张牌，然后弃置至少六张手牌",
}

local luanwu_chaos = fk.CreateCard{
  name = "&luanwu_chaos",
  type = Card.TypeTrick,
  skill = "luanwu_chaos_skill",
}
extension:addCardSpec("luanwu_chaos", Card.Club, 12)
Fk:loadTranslationTable{
  ["luanwu_chaos"] = "文和乱武",
  [":luanwu_chaos"] = "锦囊牌·<font color='grey'>群</font><br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：所有角色<br/>"..
  "<b>效果</b>：目标角色展示所有手牌，然后你选择一项：1.令其弃置两张类别不同的手牌；2.弃置其一张手牌。<br>"..
  "群：群势力角色选择完成后若没有手牌，则将手牌摸至当前体力值。",

  ["luanwu_chaos_skill"] = "文和乱武",
  ["#luanwu_chaos_skill"] = "所有角色展示手牌并令其弃置牌",
}]]

extension:loadCardSkels{
  dragon_phoenix,
  peace_spell,
  luminous_pearl,
  liulongcanjia,
  scaly_wings,
}

return extension
