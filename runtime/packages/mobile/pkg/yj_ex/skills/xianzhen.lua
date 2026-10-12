local xianzhen = fk.CreateSkill {
  name = "m_ex__xianzhen",
}

Fk:loadTranslationTable{
  ["m_ex__xianzhen"] = "陷阵",
  [":m_ex__xianzhen"] = "出牌阶段限一次，你可以与一名角色拼点，若你：赢，你于此阶段内无视其防具，且对其使用牌无距离和次数限制；"..
    "没赢，你于此阶段内不能使用【杀】。若你的拼点的牌为【杀】，你的【杀】于此回合内不计入手牌上限。",

  ["#m_ex__xianzhen-active"] = "陷阵：选择1名其他角色，与其拼点",
  ["@@m_ex__xianzhen-phase"] = "陷阵",
  ["@@m_ex__xianzhen_maxcards-turn"] = "陷阵",

  ["$m_ex__xianzhen1"] = "陷阵之志，有死无生！",
  ["$m_ex__xianzhen2"] = "攻则破城，战则克敌。",
}

xianzhen:addEffect("active", {
  anim_type = "offensive",
  prompt = "#m_ex__xianzhen-active",
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

    if pindian.fromCard and pindian.fromCard.trueName == "slash" then
      room:addPlayerMark(player, "@@m_ex__xianzhen_maxcards-turn")
    end
    if pindian.results[target].winner == player then
      room:addPlayerMark(target, "@@m_ex__xianzhen-phase")
      room:addTableMark(player, "m_ex__xianzhen_target-phase", target.id)
      room:addTableMark(player, MarkEnum.MarkArmorInvalidTo .. "-phase", target.id)
    else
      room:addPlayerMark(player, "m_ex__xianzhen_prohibit-phase")
    end
  end,
})

xianzhen:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and to and table.contains(player:getTableMark("m_ex__xianzhen_target-phase"), to.id)
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and to and table.contains(player:getTableMark("m_ex__xianzhen_target-phase"), to.id)
  end,
})

xianzhen:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return player:getMark("m_ex__xianzhen_prohibit-phase") > 0 and card.trueName == "slash"
  end,
})

xianzhen:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return player:getMark("@@m_ex__xianzhen_maxcards-turn") > 0 and card.trueName == "slash"
  end,
})

return xianzhen
