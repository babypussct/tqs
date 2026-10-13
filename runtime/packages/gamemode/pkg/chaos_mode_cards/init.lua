-- SPDX-License-Identifier: GPL-3.0-or-later

local extension = Package:new("chaos_mode_cards", Package.CardPack)
extension.extensionName = "gamemode"
extension.game_modes_blacklist = {
  "aaa_role_mode",
  "m_1v1_mode",
  "m_1v2_mode",
  "m_2v2_mode",
  "zombie_mode",
  "heg_mode",
}

extension:loadSkillSkelsByPath("./packages/gamemode/pkg/chaos_mode_cards/skills")

Fk:loadTranslationTable{
  ["chaos_mode_cards"] = "文和乱武",
}

extension:addCardSpec("poison")

extension:addCardSpec("time_flying", Card.Heart, 1)
extension:addCardSpec("time_flying", Card.Diamond, 5)

extension:addCardSpec("substituting", Card.Heart, 1)
extension:addCardSpec("substituting", Card.Heart, 13)
extension:addCardSpec("substituting", Card.Diamond, 12)

extension:addCardSpec("replace_with_a_fake", Card.Spade, 11)
extension:addCardSpec("replace_with_a_fake", Card.Spade, 13)
extension:addCardSpec("replace_with_a_fake", Card.Club, 12)
extension:addCardSpec("replace_with_a_fake", Card.Club, 13)

extension:addCardSpec("wenhe_chaos", Card.Spade, 10)
extension:addCardSpec("wenhe_chaos", Card.Club, 4)

extension:addCardSpec("forced_exchange", Card.Spade, 1)
extension:addCardSpec("forced_exchange", Card.Club, 12)
extension:addCardSpec("forced_exchange", Card.Club, 13)

extension:addCardSpec("armed_and_fed", Card.Heart, 3)
extension:addCardSpec("armed_and_fed", Card.Heart, 4)

local poison = fk.CreateCard{
  name = "&poison",
  type = Card.TypeBasic,
  skill = "poison_skill",
}
Fk:loadTranslationTable{
  ["poison"] = "毒",
  [":poison"] = "基本牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：体力值大于0的你<br/>"..
  "<b>效果</b>：目标角色失去1点体力。<br>当此牌正面朝上离开你的手牌区后，你失去1点体力。",

  ["poison_skill"] = "毒",
  ["#poison_skill"] = "你失去1点体力",
}

local time_flying = fk.CreateCard{
  name = "&time_flying",
  type = Card.TypeTrick,
  skill = "time_flying_skill",
}
Fk:loadTranslationTable{
  ["time_flying"] = "斗转星移",
  [":time_flying"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：一名其他角色<br/>"..
  "<b>效果</b>：随机分配你和目标角色的体力（至少为1且无法超出上限）。",

  ["time_flying_skill"] = "斗转星移",
  ["#time_flying_skill"] = "选择一名其他角色，与其随机分配体力",
}

local substituting = fk.CreateCard{
  name = "&substituting",
  type = Card.TypeTrick,
  skill = "substituting_skill",
}
Fk:loadTranslationTable{
  ["substituting"] = "李代桃僵",
  [":substituting"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：一名其他角色<br/>"..
  "<b>效果</b>：随机分配你和目标角色的手牌。",

  ["substituting_skill"] = "李代桃僵",
  ["#substituting_skill"] = "选择一名其他角色，与其随机分配手牌",
}

local replace_with_a_fake = fk.CreateCard{
  name = "&replace_with_a_fake",
  type = Card.TypeTrick,
  skill = "replace_with_a_fake_skill",
}
Fk:loadTranslationTable{
  ["replace_with_a_fake"] = "偷梁换柱",
  [":replace_with_a_fake"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：你<br/>"..
  "<b>效果</b>：随机分配所有角色装备区里的牌。",

  ["replace_with_a_fake_skill"] = "偷梁换柱",
  ["#replace_with_a_fake_skill"] = "随机分配所有角色装备区里的牌",
}

local wenhe_chaos = fk.CreateCard{
  name = "&wenhe_chaos",
  type = Card.TypeTrick,
  skill = "wenhe_chaos_skill",
  multiple_targets = true,
}
Fk:loadTranslationTable{
  ["wenhe_chaos"] = "文和乱武",
  [":wenhe_chaos"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：所有其他角色<br/>"..
  "<b>效果</b>：目标角色选择一项：1.对距离最近的一名角色使用【杀】；2.失去1点体力。",

  ["wenhe_chaos_skill"] = "文和乱武",
  ["#wenhe_chaos_skill"] = "令所有其他角色选择使用【杀】或失去体力",
}

-- 线下

local forced_exchange = fk.CreateCard{
  name = "&forced_exchange",
  type = Card.TypeTrick,
  skill = "forced_exchange_skill",
}

Fk:loadTranslationTable{
  ["forced_exchange"] = "强易",
  [":forced_exchange"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：一名有手牌的其他角色<br/>"..
  "<b>效果</b>：你交给目标角色2枚“粮草”并观看其手牌，获得其手牌区或装备区的一张牌。",

  ["forced_exchange_skill"] = "强易",
  ["#forced_exchange_skill"] = "选择一名其他角色，交给其2枚“粮草”，观看其手牌并获得其一张牌",
}

local armed_and_fed = fk.CreateCard{
  name = "&armed_and_fed",
  type = Card.TypeTrick,
  skill = "armed_and_fed_skill",
}

Fk:loadTranslationTable{
  ["armed_and_fed"] = "强兵足食",
  [":armed_and_fed"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：你<br/>"..
  "<b>效果</b>：目标角色获得5枚“粮草”。",

  ["armed_and_fed_skill"] = "强兵足食",
  ["#armed_and_fed_skill"] = "获得5枚“粮草”",
}

extension:loadCardSkels {
  poison,
  time_flying,
  substituting,
  replace_with_a_fake,
  wenhe_chaos,
  forced_exchange,
  armed_and_fed,
}

return extension
