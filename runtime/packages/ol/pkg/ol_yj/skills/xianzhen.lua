local xianzhen = fk.CreateSkill {
  name = "ol__xianzhen"
}

Fk:loadTranslationTable{
  ["ol__xianzhen"] = "陷阵",
  [":ol__xianzhen"] = "出牌阶段限一次，你可以拼点：若你赢，你本回合被拼点者使用牌无距离限制且无视其防具牌，你使用仅指定唯一目标的【杀】或普通锦囊牌可以多指定其为目标；"..
  "若你没赢，你本回合不能使用【杀】且你的【杀】不计入手牌上限。",

  ["#ol__xianzhen"] = "陷阵：与一名角色拼点，若赢，你对其使用牌无距离限制且无视防具，且使用牌可指定其为额外目标",
  ["@@ol__xianzhen-turn"] = "陷阵",

  ["$ol__xianzhen1"] = "攻无不克，战无不胜！",
  ["$ol__xianzhen2"] = "破阵斩将，易如反掌！",
}

xianzhen:addEffect("active", {
  aniol_type = "offensive",
  prompt = "#ol__xianzhen",
  max_phase_use_time = 1,
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(xianzhen.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and player:canPindian(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local pindian = player:pindian({target}, self.name)
    if pindian.results[target].winner == player then
      room:addTableMark(player, "ol__xianzhen_target-turn", target.id)
      room:addPlayerMark(target, "@@ol__xianzhen-turn")
      room:addPlayerMark(player, "ol__xianzhen-turn")
      room:addTableMark(player, MarkEnum.MarkArmorInvalidTo .. "-turn", target.id)
    else
      room:addPlayerMark(player, "ol__xianzhen_prohibit-turn")
    end
  end,
})

xianzhen:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("ol__xianzhen-turn") ~= 0 
    and (data.card.trueName == "slash" or data.card:isCommonTrick())    
    and data:isOnlyTarget(data.tos[1]) and not table.find(data.tos, function(p) 
      return p:getMark("@@ol__xianzhen-turn") ~= 0 
    end) 
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return p:getMark("@@ol__xianzhen-turn") ~= 0 
    end)
    return room:askToSkillInvoke(player, {
      skill_name = xianzhen.name,
      prompt = "#ol__xianzhen-ask:" .. targets[1].id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return p:getMark("@@ol__xianzhen-turn") ~= 0 
    end)
    data:addTarget(targets[1])
  end,
})

xianzhen:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and to and table.contains(player:getTableMark("ol__xianzhen_target-turn"), to.id)
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and to and table.contains(player:getTableMark("ol__xianzhen_target-turn"), to.id) 
  end,
})

xianzhen:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return player:getMark("ol__xianzhen_lose-turn") > 0 and card.trueName == "slash"
  end,
})

xianzhen:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return player:getMark("ol__xianzhen_lose-turn") > 0 and card.trueName == "slash"
  end,
})

return xianzhen