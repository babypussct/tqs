local zhilve = fk.CreateSkill {
  name = "zhilve",
}

Fk:loadTranslationTable{
  ["zhilve"] = "知略",
  [":zhilve"] = "出牌阶段限一次，你可以失去1点体力令你本回合手牌上限+1，并选择一项：1.移动场上一张牌；2.摸一张牌并视为使用一张"..
  "无距离次数限制的【杀】。",

  ["#zhilve"] = "知略：失去1点体力令本回合手牌上限+1，然后执行选项",
  ["zhilve1"] = "移动场上一张牌",
  ["zhilve2"] = "摸一张牌并视为使用杀",

  ["$zhilve1"] = "将者，上不制天，下不制地，中不制人。",
  ["$zhilve2"] = "料敌之计，明敌之意，因况反制。",
}

zhilve:addEffect("active", {
  anim_type = "offensive",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 2,
  prompt = "#zhilve",
  interaction = UI.ComboBox {choices = {"zhilve1", "zhilve2"}},
  can_use = function(self, player)
    return player:usedSkillTimes(zhilve.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if self.interaction.data == "zhilve1" then
      if #selected == 0 then
        return true
      elseif #selected == 1 then
        return table.find(selected[1]:getCardIds("ej"), function(id)
          return selected[1]:canMoveCardInBoardTo(to_select, id)
        end) or table.find(to_select:getCardIds("ej"), function(id)
          return to_select:canMoveCardInBoardTo(selected[1], id)
        end)
      end
    else
      return #selected == 0 and to_select ~= player and
        player:canUseTo(Fk:cloneCard("slash"), to_select, {bypass_distances = true, bypass_times = true})
    end
  end,
  feasible = function (self, player, selected, selected_cards)
    if self.interaction.data == "zhilve1" then
      return #selected == 2
    elseif self.interaction.data == "zhilve2" then
      return #selected == 1
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    if self.interaction.data == "zhilve1" then
      local result = room:askToMoveCardInBoard(player, {
        target_one = effect.tos[1],
        target_two = effect.tos[2],
        skill_name = zhilve.name,
        skip = true
      })
      if result == nil then return end
      local area = room:getCardArea(result.card)
      room:loseHp(player, 1, zhilve.name)
      if not player.dead then
        room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, 1)
      end
      if room:getCardArea(result.card) == area and room:getCardOwner(result.card) == result.from and not result.to.dead and
        result.from:canMoveCardInBoardTo(result.to, result.card:getEffectiveId()) then
        room:moveCardTo(result.card, area, result.to, fk.ReasonJustMove, zhilve.name, nil, true, player)
      end
    else
      room:loseHp(player, 1, zhilve.name)
      if not player.dead then
        room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, 1)
        player:drawCards(1, zhilve.name)
      end
      room:useVirtualCard("slash", nil, player, effect.tos[1], zhilve.name, true)
    end
  end,
})

return zhilve
