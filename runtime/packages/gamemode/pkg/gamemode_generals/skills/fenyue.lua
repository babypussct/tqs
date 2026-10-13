local fenyue = fk.CreateSkill {
  name = "vd__fenyue",
}

Fk:loadTranslationTable{
  ["vd__fenyue"] = "奋钺",
  [":vd__fenyue"] = "出牌阶段限X次，你可以与一名角色拼点，若你赢，你选择一项：1.其不能使用或打出手牌直到回合结束；"..
  "2.视为你对其使用一张不计入次数的【杀】。若你没赢，你结束出牌阶段（X为存活的忠臣数）。",

  ["#vd__fenyue"] = "奋钺：与一名角色拼点，若赢，选择视为对其使用【杀】或禁止其使用打出手牌",

  ["vd__fenyue_slash"] = "视为对其使用【杀】",
  ["vd__fenyue_prohibit"] = "本回合禁止其使用打出手牌",
  ["@@vd__fenyue-turn"] = "禁用手牌",
}

fenyue:addEffect("active", {
  anim_type = "offensive",
  prompt = "#vd__fenyue",
  card_num = 0,
  target_num = 1,
  times = function(self, player)
    return player.phase == Player.Play and
      #table.filter(Fk:currentRoom().alive_players, function (p)
        return p.role == "loyalist"
      end) - player:usedSkillTimes(fenyue.name, Player.HistoryPhase) or -1
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(fenyue.name, Player.HistoryPhase) <
      #table.filter(Fk:currentRoom().alive_players, function (p)
        return p.role == "loyalist"
      end)
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and player:canPindian(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local pindian = player:pindian({target}, fenyue.name)
    if pindian.results[target].winner == player then
      if target.dead then return end
      if player:prohibitUse(Fk:cloneCard("slash")) or player:isProhibited(target, Fk:cloneCard("slash")) or
        room:askToChoice(player, {
          choices = {"vd__fenyue_slash", "vd__fenyue_prohibit"},
          skill_name = fenyue.name,
        }) == "vd__fenyue_prohibit" then
        room:setPlayerMark(target, "@@vd__fenyue-turn", 1)
      else
        room:useVirtualCard("slash", nil, player, target, fenyue.name, true)
      end
    else
      player:endPlayPhase()
    end
  end,
})

fenyue:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if player:getMark("@@vd__fenyue-turn") > 0 then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds("h"), id)
      end)
    end
  end,
  prohibit_response = function(self, player, card)
    if player:getMark("@@vd__fenyue-turn") > 0 then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds("h"), id)
      end)
    end
  end,
})

return fenyue
