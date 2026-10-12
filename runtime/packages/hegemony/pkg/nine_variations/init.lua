
local extension = Package:new("nine_variations", Package.CardPack)
extension.extensionName = "hegemony"
extension:loadSkillSkelsByPath("./packages/hegemony/pkg/nine_variations/skills")

Fk:loadTranslationTable{
  ["nine_variations"] = "国战·九变篇",
  ["rare_treasure"] = "奇珍",
  [":rare_treasure"] = [[奇珍牌：装备区内拥有奇珍牌的角色，受到【杀】造成的伤害后，伤害来源可以获得其装备区的一张奇珍牌。<br/>奇珍牌包括
      <a href=':serpent_slayer_sword'>【斩蛇剑】</a>、
      <a href=':yangsui_spear'>【阳燧枪】</a>、
      <a href=':amiantus_robe'>【火浣衣】</a>、
      <a href=':white_kylin'>【白麒麟】</a>、
      <a href=':tianlu'>【天禄】</a>、
      <a href=':dunjia_book'>【遁甲天书】</a>、
      <a href=':turban_shell_cup'>【鹦鹉杯】</a>、
      <a href=':nine_tripod_cauldrons'>【九州鼎】</a>。]],
  ["#rare_treasure-prey"] = "是否获得 %dest 装备区里的一张奇珍牌？",
}

extension.game_modes_whitelist = { "new_heg_mode" }

local H = require "packages.hegemony.util"

extension:addCardSpec("slash", Card.Spade, 4)
extension:addCardSpec("slash", Card.Spade, 5)
extension:addCardSpec("slash", Card.Club, 4)
extension:addCardSpec("slash", Card.Club, 5)
extension:addCardSpec("slash", Card.Club, 6)
extension:addCardSpec("slash", Card.Club, 7)
extension:addCardSpec("slash", Card.Club, 10)
extension:addCardSpec("slash", Card.Diamond, 9)

extension:addCardSpec("thunder__slash", Card.Spade, 6)
extension:addCardSpec("thunder__slash", Card.Spade, 7)
extension:addCardSpec("thunder__slash", Card.Spade, 8)
extension:addCardSpec("thunder__slash", Card.Club, 8)

extension:addCardSpec("fire__slash", Card.Heart, 7)
extension:addCardSpec("fire__slash", Card.Diamond, 3)
extension:addCardSpec("fire__slash", Card.Diamond, 4)

extension:addCardSpec("analeptic", Card.Spade, 9)
extension:addCardSpec("analeptic", Card.Club, 9)

extension:addCardSpec("jink", Card.Diamond, 6)
extension:addCardSpec("jink", Card.Diamond, 7)
extension:addCardSpec("jink", Card.Diamond, 8)

local rob__jink = fk.CreateCard{
  name = "rob__jink",
  type = Card.TypeBasic,
  skill = "#rob__jink_skill",
  is_passive = true,
}
extension:addCardSpec("rob__jink", Card.Heart, 8)
extension:addCardSpec("rob__jink", Card.Heart, 10)
extension:addCardSpec("rob__jink", Card.Heart, 11)
extension:addCardSpec("rob__jink", Card.Heart, 12)
Fk:loadTranslationTable{
  ["rob__jink"] = "掠闪",
  [":rob__jink"] = "基本牌<br/>"..
  "<b>时机</b>：【杀】对你生效时<br/>"..
  "<b>目标</b>：此【杀】<br/>"..
  "<b>效果</b>：抵消此【杀】的效果，然后你可以获得此【杀】使用者装备区里的一张<a href=':rare_treasure'>奇珍牌</a>。",
  ["#rob__jink_skill"] = "掠闪",
}

extension:addCardSpec("peach", Card.Heart, 4)
extension:addCardSpec("peach", Card.Heart, 5)
extension:addCardSpec("peach", Card.Heart, 6)
extension:addCardSpec("peach", Card.Diamond, 5)

local reveal_intention = fk.CreateCard{
  name = "reveal_intention",
  type = Card.TypeTrick,
  skill = "reveal_intention_skill",
}
extension:addCardSpec("reveal_intention", Card.Club, 1)
extension:addCardSpec("reveal_intention", Card.Club, 2)
extension:addCardSpec("reveal_intention", Card.Club, 11)
Fk:loadTranslationTable{
  ["reveal_intention"] = "图穷匕见",
  [":reveal_intention"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：一名其他角色<br/>"..
  "<b>效果</b>：你选择弃牌堆中一张<a href=':rare_treasure'>奇珍牌</a>，目标使用之；目标本回合视为在你攻击范围内。",

  ["reveal_intention_skill"] = "图穷匕见",
  ["#reveal_intention_skill"] = "选择一名角色，其使用弃牌堆中一张奇珍牌，本回合视为在你攻击范围内",
  ["#reveal_intention-ask"] = "选择其中一张奇珍牌，令 %dest 使用之",
}

local overbearing = fk.CreateCard{
  name = "overbearing",
  type = Card.TypeTrick,
  skill = "overbearing_skill",
  is_damage_card = true,
  damage_type = fk.NormalDamage,
}
extension:addCardSpec("overbearing", Card.Spade, 10)
extension:addCardSpec("overbearing", Card.Spade, 11)
extension:addCardSpec("overbearing", Card.Club, 12)
extension:addCardSpec("overbearing", Card.Club, 13)
Fk:loadTranslationTable{
  ["overbearing"] = "咄咄逼人",
  [":overbearing"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：一名确定势力的角色<br/>"..
  "<b>效果</b>：目标可以变更副将，然后你对目标造成1点伤害。",

  ["overbearing_skill"] = "咄咄逼人",
  ["#overbearing_skill"] = "令一名角色可以变更副将，然后你对其造成1点伤害",
}

local part_ways = fk.CreateCard{
  name = "part_ways",
  type = Card.TypeTrick,
  skill = "part_ways_skill",
  special_skills = { "recast" },
}
extension:addCardSpec("part_ways", Card.Heart, 2)
Fk:loadTranslationTable{
  ["part_ways"] = "分道扬镳",
  [":part_ways"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：一名与你势力相同的其他角色<br/>"..
  "<b>效果</b>：你摸六张牌并交给目标三张牌，然后你成为野心家。",

  ["part_ways_skill"] = "分道扬镳",
  ["#part_ways_skill"] = "选择一名同势力其他角色，摸六张牌并交给其三张牌，你成为野心家",
  ["#part_ways-give"] = "请交给 %dest 三张牌",
}

local tricky_heist = fk.CreateCard{
  name = "tricky_heist",
  type = Card.TypeTrick,
  skill = "tricky_heist_skill",
  multiple_targets = true,
}
extension:addCardSpec("tricky_heist", Card.Heart, 1)
extension:addCardSpec("tricky_heist", Card.Heart, 3)
extension:addCardSpec("tricky_heist", Card.Diamond, 10)
extension:addCardSpec("tricky_heist", Card.Spade, 10)
Fk:loadTranslationTable{
  ["tricky_heist"] = "巧取豪夺",
  [":tricky_heist"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：至多两名其他角色<br/>"..
  "<b>效果</b>：目标依次展示手牌，然后你获得目标所有因此展示的装备牌。",

  ["tricky_heist_skill"] = "巧取豪夺",
  ["#tricky_heist_skill"] = "令至多两名其他角色展示手牌，你获得所有因此展示的装备牌",
}

local unworthy_continuation = fk.CreateCard{
  name = "unworthy_continuation",
  type = Card.TypeTrick,
  skill = "unworthy_continuation_skill",
  multiple_targets = true,
}
extension:addCardSpec("unworthy_continuation", Card.Diamond, 1)
extension:addCardSpec("unworthy_continuation", Card.Diamond, 2)
Fk:loadTranslationTable{
  ["unworthy_continuation"] = "狗尾续貂",
  [":unworthy_continuation"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：所有角色<br/>"..
  "<b>效果</b>：每名目标依次选择并使用弃牌堆中的一张<a href=':rare_treasure'>奇珍牌</a>，没有则改为摸一张牌。",

  ["unworthy_continuation_skill"] = "狗尾续貂",
  ["#unworthy_continuation_skill"] = "所有角色使用弃牌堆中的一张奇珍牌，没有则改为摸一张牌",
  ["#unworthy_continuation-ask"] = "请使用其中一张奇珍牌",
}

extension:addCardSpec("nullification", Card.Club, 12)
extension:addCardSpec("nullification", Card.Club, 13)
extension:addCardSpec("nullification", Card.Diamond, 13)
extension:addCardSpec("heg__nullification", Card.Club, 13)

local serpent_slayer_sword = fk.CreateCard{
  name = "serpent_slayer_sword",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 2,
  equip_skill = "#serpent_slayer_sword_skill",
}
extension:addCardSpec("serpent_slayer_sword", Card.Spade, 1)
Fk:loadTranslationTable{
  ["serpent_slayer_sword"] = "斩蛇剑",
  [":serpent_slayer_sword"] = "装备牌·武器 [<a href=':rare_treasure'>奇珍牌</a>]<br/>"..
  "<b>攻击范围</b>：2<br/>"..
  "<b>武器技能</b>：你使用【杀】对目标造成伤害后，你回复1点体力，若其为君主或野心家，杀死该角色。",
  ["#serpent_slayer_sword_skill"] = "斩蛇剑",
}

local yangsui_spear = fk.CreateCard{
  name = "yangsui_spear",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 3,
  equip_skill = "#yangsui_spear_skill",
}
extension:addCardSpec("yangsui_spear", Card.Diamond, 11)
Fk:loadTranslationTable{
  ["yangsui_spear"] = "阳燧枪",
  [":yangsui_spear"] = "装备牌·武器 [<a href=':rare_treasure'>奇珍牌</a>]<br/>"..
  "<b>攻击范围</b>：3<br/>"..
  "<b>武器技能</b>：锁定技，当你使用【杀】对目标造成伤害后，其再受到1点无来源火焰伤害。",
  ["#yangsui_spear_skill"] = "阳燧枪",
}

local amiantus_robe = fk.CreateCard{
  name = "amiantus_robe",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeArmor,
  equip_skill = "#amiantus_robe_skill",
}
extension:addCardSpec("amiantus_robe", Card.Diamond, 12)
Fk:loadTranslationTable{
  ["amiantus_robe"] = "火浣衣",
  [":amiantus_robe"] = "装备牌·防具 [<a href=':rare_treasure'>奇珍牌</a>]<br/>"..
  "<b>防具技能</b>：防止你受到的属性伤害；当你成为【杀】的目标后，你可以弃置一张手牌对使用者造成1点火焰伤害。",
  ["#amiantus_robe_skill"] = "火浣衣",
  ["#amiantus_robe-invoke"] = "火浣衣：你可以弃置一张手牌，对 %dest 造成1点火焰伤害",
}

local white_kylin = fk.CreateCard{
  name = "white_kylin",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeDefensiveRide,
  equip_skill = "#white_kylin_skill",
  ui_name = "+2",
}
extension:addCardSpec("white_kylin", Card.Spade, 2)
Fk:loadTranslationTable{
  ["white_kylin"] = "白麒麟",
  [":white_kylin"] = "装备牌·坐骑 [<a href=':rare_treasure'>奇珍牌</a>]<br/>"..
  "<b>坐骑技能</b>：其他角色与你的距离+2。你使用此牌时，对所有体力值大于你的角色依次造成1点雷电伤害。",
  ["#white_kylin_skill"] = "白麒麟",
}

local tianlu = fk.CreateCard{
  name = "tianlu",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeOffensiveRide,
  equip_skill = "#tianlu_skill",
  ui_name = "-3",
  dynamic_equip_skills = function (self, player)
    local skills = { Fk.skills["#tianlu_skill"] }
    if H.getHegLord(Fk:currentRoom(), player) == nil and player.kingdom ~= "unknown" then
      local kingdom = H.getKingdom(player)
      if kingdom == "wei" then -- FIXME: 1.只在上装时判断；2.手杀君主？
        table.insert(skills, Fk.skills["jianan"] )
      elseif kingdom == "shu" then
        table.insert(skills, Fk.skills["shouyue"] )
      elseif kingdom == "wu" then
        table.insert(skills, Fk.skills["jiahe"] )
      elseif kingdom == "qun" then
        table.insert(skills, Fk.skills["hongfa"] )
      elseif kingdom == "jin" then
        table.insert(skills, Fk.skills["heg__jiaping"] )
      end
    end
    return skills
  end,
}
extension:addCardSpec("tianlu", Card.Club, 3)
Fk:loadTranslationTable{
  ["tianlu"] = "天禄",
  [":tianlu"] = "装备牌·坐骑 [<a href=':rare_treasure'>奇珍牌</a>]<br/>"..
  "<b>坐骑技能</b>：你与其他角色的距离-3。若场上没有与你势力相同的君主，你视为拥有你势力的君主技。",
  ["#tianlu_skill"] = "天禄",
}

local dunjia_book = fk.CreateCard{
  name = "dunjia_book",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
  equip_skill = "dunjia_book_skill&",
  on_uninstall = function(self, room, player)
    Treasure.onUninstall(self, room, player)
    player:setSkillUseHistory(self.equip_skill.name, 0, Player.HistoryPhase)
  end,
}
extension:addCardSpec("dunjia_book", Card.Spade, 3)
Fk:loadTranslationTable{
  ["dunjia_book"] = "遁甲天书",
  [":dunjia_book"] = "装备牌·宝物 [<a href=':rare_treasure'>奇珍牌</a>]<br/>"..
  "<b>宝物技能</b>：出牌阶段限两次，你可以变更副将。",
  ["dunjia_book_skill&"] = "遁甲天书",
  [":dunjia_book_skill&"] = "出牌阶段限两次，你可以变更副将。",
  ["#dunjia_book_skill&"] = "遁甲天书：你可以变更副将",
}

local turban_shell_cup = fk.CreateCard{
  name = "turban_shell_cup",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
  equip_skill = "turban_shell_cup_skill&",
  on_uninstall = function(self, room, player)
    Treasure.onUninstall(self, room, player)
    player:setSkillUseHistory(self.equip_skill.name, 0, Player.HistoryTurn)
  end,
}
extension:addCardSpec("turban_shell_cup", Card.Heart, 9)
Fk:loadTranslationTable{
  ["turban_shell_cup"] = "鹦鹉杯",
  [":turban_shell_cup"] = "装备牌·宝物 [<a href=':rare_treasure'>奇珍牌</a>]<br/>"..
  "<b>宝物技能</b>：每回合限九次，你可以将牌堆顶的牌当【酒】使用。",
  ["turban_shell_cup_skill&"] = "鹦鹉杯",
  [":turban_shell_cup_skill&"] = "每回合限九次，你可以将牌堆顶的牌当【酒】使用。",
  ["#turban_shell_cup_skill&"] = "鹦鹉杯：你可以将牌堆顶的牌当【酒】使用",
}

local nine_tripod_cauldrons = fk.CreateCard{
  name = "nine_tripod_cauldrons",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
  equip_skill = "#nine_tripod_cauldrons_skill",
}
extension:addCardSpec("nine_tripod_cauldrons", Card.Heart, 13)
Fk:loadTranslationTable{
  ["nine_tripod_cauldrons"] = "九州鼎",
  [":nine_tripod_cauldrons"] = "装备牌·宝物 [<a href=':rare_treasure'>奇珍牌</a>]<br/>"..
  "<b>宝物技能</b>：分发手牌前或洗牌后，将此牌从牌堆内置于弃牌堆。"..
  "锁定技，若你装备区内有四张或以上<a href=':rare_treasure'>奇珍牌</a>，你当前阵营获得游戏胜利。",
  ["#nine_tripod_cauldrons_skill"] = "九州鼎",
}

extension:loadCardSkels{
  rob__jink,

  reveal_intention,
  overbearing,
  part_ways,
  tricky_heist,
  unworthy_continuation,

  serpent_slayer_sword,
  yangsui_spear,
  amiantus_robe,
  white_kylin,
  tianlu,
  dunjia_book,
  turban_shell_cup,
  nine_tripod_cauldrons,
}

return extension
