local xianzhen = fk.CreateSkill {
  name = "ol_ex__xianzhen",
}

Fk:loadTranslationTable{
  ["ol_ex__xianzhen"] = "陷阵",
  [":ol_ex__xianzhen"] = "出牌阶段限一次，你可以与一名角色拼点，若你赢，你本回合内对其使用牌无距离和次数限制且无视其防具，你使用【杀】或普通锦囊牌能多指定其为目标；"..
    "若你没赢，你本回合不能对其使用【杀】且你的【杀】不计入手牌上限。",

  ["#ol_ex__xianzhen-active"] = "陷阵：选择1名其他角色，与其拼点",
  ["#ol_ex__xianzhen-ask"] = "陷阵：是否额外指定 %src 为目标",
  ["@@ol_ex__xianzhen-phase"] = "陷阵",

  ["$ol_ex__xianzhen1"] = "陷阵之志，有死无生！",
  ["$ol_ex__xianzhen2"] = "攻则破城，战则克敌。",
}

xianzhen:addEffect("active", {
  aniol_type = "offensive",
  prompt = "#ol_ex__xianzhen-active",
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
    room:addTableMark(player, "ol_ex__xianzhen_target-phase", target.id)
    if pindian.results[target].winner == player then
      room:addPlayerMark(player, "ol_ex__xianzhen-phase")
      room:addPlayerMark(target, "@@ol_ex__xianzhen-phase")
      room:addTableMark(player, MarkEnum.MarkArmorInvalidTo .. "-phase", target.id)
    else
      room:addPlayerMark(player, "ol_ex__xianzhen_prohibit-turn")
    end
  end,
})

xianzhen:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("ol_ex__xianzhen-phase") ~= 0 
    and (data.card.trueName == "slash" or data.card:isCommonTrick())    
    and not table.find(data.tos, function(p) 
      return p:getMark("@@ol_ex__xianzhen-phase") ~= 0 
    end) 
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return p:getMark("@@ol_ex__xianzhen-phase") ~= 0 
    end)
    return room:askToSkillInvoke(player, {
      skill_name = xianzhen.name,
      prompt = "#ol_ex__xianzhen-ask:" .. targets[1].id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return p:getMark("@@ol_ex__xianzhen-phase") ~= 0 
    end)
    data:addTarget(targets[1])
  end,
})


xianzhen:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and to and table.contains(player:getTableMark("ol_ex__xianzhen_target-phase"), to.id) and to:getMark("@@ol_ex__xianzhen-phase") > 0
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and to and table.contains(player:getTableMark("ol_ex__xianzhen_target-phase"), to.id) and to:getMark("@@ol_ex__xianzhen-phase") > 0
  end,
})

xianzhen:addEffect("prohibit", {
  is_prohibited = function (self, from, to, card)
    return from and from:getMark("ol_ex__xianzhen_prohibit-turn") > 0 and card and card.trueName == "slash" and table.contains(from:getTableMark("ol_ex__xianzhen_target-phase"), to.id)
  end,
})
xianzhen:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return player:getMark("ol_ex__xianzhen_prohibit-turn") > 0 and card.trueName == "slash"
  end,
})

return xianzhen
