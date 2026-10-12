
local gucheng = fk.CreateSkill{
  name = "gucheng",
}

Fk:loadTranslationTable{
  ["gucheng"] = "孤城",
  [":gucheng"] = "出牌阶段限一次，你可以与一名其他角色依次拼点，直到你没赢，然后你摸X张牌（X为你本阶段拼点的次数）。"..
  "若X为1，你弃置其一张牌，然后本回合你使用【杀】无次数限制。",

  ["#gucheng"] = "孤城：你可以与一名角色拼点直到你没赢，你摸拼点次数张牌",
  ["#gucheng-discard"] = "孤城：弃置 %dest 一张牌",
  ["@@gucheng-turn"] = "孤城",

  ["$gucheng1"] = "茕茕孤城守，此去经二年。",
  ["$gucheng2"] = "重重相围困，庐江大风寒。",
}

gucheng:addEffect("active", {
  anim_type = "offensive",
  prompt = "#gucheng",
  max_phase_use_time = 1,
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(gucheng.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and player:canPindian(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    while not player.dead and player:canPindian(target) do
      local pindian = player:pindian({ target }, gucheng.name)
      if player.dead then return end
      if pindian.results[target].winner ~= player then
        break
      end
    end
    if player.dead then return end
    local n = #room.logic:getEventsOfScope(GameEvent.Pindian, 999, function(e)
      return e.data.from == player or e.data.results[player] ~= nil
    end, Player.HistoryTurn)
    player:drawCards(n, gucheng.name)
    if n == 1 and not player.dead then
      room:setPlayerMark(player, "@@gucheng-turn", 1)
      if not target:isNude() then
        local id = room:askToChooseCard(player, {
          target = target,
          flag = "he",
          skill_name = gucheng.name,
        })
        room:throwCard(id, gucheng.name, target, player)
      end
    end
  end,
})

gucheng:addEffect("targetmod", {
  bypass_times = function (self, player, skill, scope, card, to)
    return player:getMark("@@gucheng-turn") > 0 and card and card.trueName == "slash"
  end,
})

return gucheng
