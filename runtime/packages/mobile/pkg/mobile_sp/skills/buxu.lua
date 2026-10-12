local buxu = fk.CreateSkill {
  name = "buxu",
}

Fk:loadTranslationTable{
  ["buxu"] = "补续",
  [":buxu"] = "出牌阶段，若你拥有技能〖承业〗，你可以弃置X张牌并选择一种你缺失的<a href='chengye_href'>“六经”</a>，"..
  "然后从牌堆或弃牌堆中随机获得一张对应此“六经”的牌加入“典”中（X为你本阶段此前成功发动过此技能的次数+1）。",
  ["#buxu-choice"] = "补续：选择一种你缺失的“六经”获得",

  ["cy_classic_nullification"] = "礼",
  ["cy_classic_ex_nihilo"] = "易",
  ["cy_classic_indulgence"] = "乐",
  ["cy_classic_basic"] = "书",
  ["cy_classic_equip"] = "春秋",
  ["cy_classic_damage"] = "诗",
  [":cy_classic_nullification"] = "无懈可击",
  [":cy_classic_ex_nihilo"] = "无中生有",
  [":cy_classic_indulgence"] = "乐不思蜀",
  [":cy_classic_basic"] = "基本牌",
  [":cy_classic_equip"] = "装备牌",
  [":cy_classic_damage"] = "伤害类锦囊牌",
  ["#BuXuFalid"] = "%from 发动 %arg 失败，无法检索到 %arg2",

  ["$buxu1"] = "今世俗儒穿凿，不加补续，恐疑误后学。",
  ["$buxu2"] = "经籍去圣久远，文字多谬，当正定《六经》。",
}

local getClassicsType = function (cardId)
  local card = Fk:getCardById(cardId, true)
  if card.type == Card.TypeBasic then
    return "cy_classic_basic"
  elseif card.type == Card.TypeEquip then
    return "cy_classic_equip"
  elseif card.name == "nullification" or card.name == "ex_nihilo" or card.name == "indulgence" then
    return "cy_classic_"..card.name
  elseif card.is_damage_card then
    return "cy_classic_damage"
  end
  return ""
end

local getLackClassics = function (player)
  local classic = {
    "cy_classic_basic",
    "cy_classic_equip",
    "cy_classic_damage",
    "cy_classic_nullification",
    "cy_classic_ex_nihilo",
    "cy_classic_indulgence",
  }
  for _, id in ipairs(player:getPile("chengye_classic")) do
    local c = getClassicsType(id)
    table.removeOne(classic, c)
  end
  return classic
end

buxu:addEffect("active", {
  anim_type = "drawcard",
  can_use = function(self, player)
    return #player:getPile("chengye_classic") < 6
  end,
  card_num = function(self, player)
    return 1 + player:getMark("buxu-phase")
  end,
  card_filter = function (self, player, to_select, selected)
    return not player:prohibitDiscard(Fk:getCardById(to_select)) and #selected < (1 + player:getMark("buxu-phase"))
  end,
  target_num = 0,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = buxu.name
    local player = effect.from
    room:throwCard(effect.cards, skillName, player, player)
    local choice = room:askToChoice(
      player,
      {
        choices = getLackClassics(player),
        skill_name = skillName,
        prompt = "#buxu-choice",
        detailed = true,
      }
    )

    local cards = table.simpleClone(room.draw_pile)
    table.insertTable(cards, room.discard_pile)
    for i = #cards, 1, -1 do
      if getClassicsType(cards[i]) ~= choice then
        table.remove(cards, i)
      end
    end
    if #cards > 0 then
      player:addToPile("chengye_classic", room:tableRandomPick(cards), true, skillName)
      room:addPlayerMark(player, "buxu-phase")
    else
      room:sendLog{ type = "#BuXuFalid", from = player.id, arg = skillName, arg2 = ":" .. choice }
    end
  end,
})

return buxu
