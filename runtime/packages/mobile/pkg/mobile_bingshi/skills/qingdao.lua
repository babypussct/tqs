local qingdao = fk.CreateSkill {
  name = "qingdao",
}

Fk:loadTranslationTable{
  ["qingdao"] = "清蹈",
  [":qingdao"] = "当其他角色使用的伤害类卡牌结算结束后，若目标中有你，且你：受到过此牌造成的伤害，你可以从牌堆或弃牌堆中获得一张【闪】，" ..
  "或弃置一名角色区域里的一张牌；未受到过此牌造成的伤害，则你可以从牌堆或弃牌堆中获得一张【杀】，或使用一张手牌（无距离限制）。",

  ["qingdao_slash"] = "获得一张【杀】",
  ["qingdao_use"] = "使用一张手牌",
  ["qingdao_jink"] = "获得一张【闪】",
  ["qingdao_discard"] = "弃置一名角色区域里一张牌",
  ["#qingdao-invoke"] = "清蹈：你可选择一项执行",
  ["#qingdao-use"] = "清蹈：你可使用一张手牌（无距离限制）",
  ["#qingdao-discard"] = "清蹈：请选择 %dest 区域里的一张牌弃置",

  ["$qingdao1"] = "上不欺君，下不虐民，此为官之道也。",
  ["$qingdao2"] = "为官之法，惟有三事，曰清、曰慎、曰勤。",
}

qingdao:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    return
      target ~= player and
      data.card.is_damage_card and
      player:hasSkill(qingdao.name) and
      table.contains(data.tos, player)
  end,
  on_cost = function(self, event, target, player, data)
    ---@type string
    local skillName = qingdao.name
    local room = player.room
    local choices = { "qingdao_slash", "qingdao_use", "Cancel" }
    local allChoices = table.simpleClone(choices)
    if data.damageDealt and data.damageDealt[player] then
      choices = { "qingdao_jink", "qingdao_discard", "Cancel" }
      allChoices = table.simpleClone(choices)
      if not table.find(room.alive_players, function(p) return not p:isAllNude() end) then
        table.remove(choices, 2)
      end
    else
      if player:isKongcheng() then
        table.remove(choices, 2)
      end
    end

    local choice = player.room:askToChoice(
      player,
      {
        choices = choices,
        skill_name = skillName,
        prompt = "#qingdao-invoke",
        all_choices = allChoices,
      }
    )

    if choice == "Cancel" then
      return false
    end

    local effectData
    if choice == "qingdao_use" then
      local use = room:askToUseRealCard(
        player,
        {
          pattern = ".|.|.|hand",
          skill_name = skillName,
          prompt = "#qingdao-use",
          skip = true,
          extra_data = {
            bypass_distances = true,
          }
        }
      )

      if not use then
        return false
      end

      effectData = use
    elseif choice == "qingdao_discard" then
      local targets = table.filter(room.alive_players, function(p) return not p:isAllNude() end)
      if #targets == 0 then
        return false
      end

      local tos = room:askToChoosePlayers(
        player,
        {
          min_num = 1,
          max_num = 1,
          targets = targets,
          skill_name = skillName,
        }
      )

      if #tos == 0 then
        return false
      end

      effectData = tos
    end

    event:setCostData(self, { choice = choice, data = effectData })
    return true
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = qingdao.name
    local room = player.room
    local choice = event:getCostData(self).choice

    local getCardFromTwoPiles = function(pattern)
      for _, pile in ipairs({ "drawPile", "discardPile" }) do
        local cardIds = room:getCardsFromPileByRule(pattern, 1, pile)
        if #cardIds > 0 then
          room:obtainCard(player, cardIds[1], false, fk.ReasonPrey, player, skillName)
          break
        end
      end
    end
    if choice == "qingdao_slash" then
      getCardFromTwoPiles("slash")
    elseif choice == "qingdao_jink" then
      getCardFromTwoPiles("jink")
    elseif choice == "qingdao_use" then
      local use = event:getCostData(self).data
      room:useCard(use)
    else
      local to = event:getCostData(self).data[1]
      if not to:isAlive() or to:isAllNude() then
        return false
      end

      local id = room:askToChooseCard(
        player,
        {
          target = to,
          flag = "hej",
          skill_name = skillName,
          prompt = "#qingdao-discard::" .. to.id,
        }
      )

      room:throwCard(id, skillName, to, player)
    end
  end,
})

return qingdao
