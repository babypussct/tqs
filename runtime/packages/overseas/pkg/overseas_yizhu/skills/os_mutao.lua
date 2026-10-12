local osMutao = fk.CreateSkill {
  name = "os__mutao"
}

Fk:loadTranslationTable{
  ["os__mutao"] = "募讨",
  [":os__mutao"] = "出牌阶段限一次，你可选择一名其他角色，令其将手牌中的（系统选择）所有的【杀】依次交给由其下家开始的每一名角色，" ..
  "然后其对最后一名角色造成X点伤害（X为最后一名角色手牌中【杀】的数量且至多为2）。",
  ["#os__mutao"] = "选择一名角色，将其手牌中【杀】依次交给由其下家开始的除其以外的角色，然后其对最后一名角色造成伤害",

  ["$os__mutao1"] = "董贼暴乱，天下定当奋节讨之！",
  ["$os__mutao2"] = "募州郡义士，讨祸国逆贼！",
}

osMutao:addEffect("active", {
  anim_type = "offensive",
  prompt = "#os__mutao",
  times = function (self, player)
    return 1 - player:usedEffectTimes(self.name, Player.HistoryPhase)
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(osMutao.name, Player.HistoryPhase) < 1
  end,
  card_filter = Util.FalseFunc,
  card_num = 0,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and not to_select:isKongcheng() and to_select:getNextAlive() ~= to_select and to_select ~= player
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local target = effect.tos[1]
    local to = target
    local cids = table.filter(target:getCardIds("h"), function(id)
      return Fk:getCardById(id).trueName == "slash"
    end)
    local num = #cids 
    if num == 0 then
      return false
    end
    for _ = 1, num do
      
      if #cids < 1 then break end
      to = to:getNextAlive()
      local id = room:tableRandomPick(cids)
      room:moveCardTo(id, Player.Hand, to, fk.ReasonGive, osMutao.name, nil, false)
      table.removeOne(cids, id)
    end
    num = math.min(#table.filter(to:getCardIds("h"), function(id)
      return Fk:getCardById(id).trueName == "slash"
    end), 2)
    if num > 0 and not to.dead then
      room:damage {
        from = target,
        to = to,
        damage = num,
        skillName = osMutao.name,
      }
    end
  end,
})

return osMutao
