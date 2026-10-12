local fulue = fk.CreateSkill{
  name = "fulue",
}

Fk:loadTranslationTable{
  ["fulue"] = "复掠",
  [":fulue"] = "当你使用【杀】或伤害锦囊牌指定唯一目标后，你可以选择本回合未执行过的一项：1.此牌造成伤害+1；2.获得其一张牌。"..
  "此牌结算完成后，若未造成伤害，目标角色可以对你使用一张【杀】并执行另一项。",

  ["#fulue-invoke"] = "复掠：你可以对 %dest 执行一项，若未造成伤害，其可以对你使用【杀】并执行另一项",
  ["fulue_damage"] = "伤害+1",
  ["fulue_prey"] = "获得其一张牌",
  ["#fulue-use"] = "复掠：你可以对 %src 使用一张【杀】且%arg",

  ["$fulue1"] = "吹牛呢？这马日行千里，只有关将军才能骑!",
  ["$fulue2"] = "子什么？什么龙？没听说过！还不速速离去！",
}

fulue:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    if target == player and player:hasSkill(fulue.name) and data.card.is_damage_card and
      data:isOnlyTarget(data.to) and not data.to.dead and #player:getTableMark("fulue-turn") < 2 then
      if #player:getTableMark("fulue-turn") == 1 then
        if table.contains(player:getTableMark("fulue-turn"), "fulue_prey") then
          return true
        else
          return data.to == player and #player:getCardIds("e") > 0 or not data.to:isNude()
        end
      else
        return true
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choices = {"Cancel"}
    if not table.contains(player:getTableMark("fulue-turn"), "fulue_prey") and
      (data.to == player and #player:getCardIds("e") > 0 or not data.to:isNude()) then
      table.insert(choices, 1, "fulue_prey")
    end
    if not table.contains(player:getTableMark("fulue-turn"), "fulue_damage") then
      table.insert(choices, 1, "fulue_damage")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = fulue.name,
      prompt = "#fulue-invoke::"..data.to.id,
      all_choices = {"fulue_damage", "fulue_prey", "Cancel"},
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {choice = choice})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    room:addTableMark(player, "fulue-turn", choice)
    data.extra_data = data.extra_data or {}
    data.extra_data.fulue = {
      from = player,
      to = data.to,
      choice = choice,
    }
    if choice == "fulue_damage" then
      data.additionalDamage = (data.additionalDamage or 0) + 1
    else
      local card = room:askToChooseCard(player, {
        target = data.to,
        flag = data.to == player and "e" or "he",
        skill_name = fulue.name,
      })
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, fulue.name, nil, false, player)
    end
  end,
})
fulue:addEffect(fk.CardUseFinished, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return not data.damageDealt and data.extra_data and data.extra_data.fulue and
      data.extra_data.fulue.from == player and not player.dead and not data.extra_data.fulue.to.dead and
      player ~= data.extra_data.fulue.to
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = data.extra_data.fulue.to
    local choice = data.extra_data.fulue.choice == "fulue_damage" and "fulue_prey" or "fulue_damage"
    local use = room:askToUseCard(to, {
      skill_name = fulue.name,
      pattern = "slash",
      prompt = "#fulue-use:"..player.id.."::"..choice,
      extra_data = {
        bypass_distances = false,
        bypass_times = true,
        exclusive_targets = {player.id},
      }
    })
    if use then
      use.extraUse = true
      if choice == "fulue_damage" then
        use.additionalDamage = (use.additionalDamage or 0) + 1
        room:addTableMarkIfNeed(player, "fulue-turn", "fulue_damage")
      else
        use.extra_data = use.extra_data or {}
        use.extra_data.fulue_delay = {
          from = player,
          to = to,
        }
      end
      room:useCard(use)
    end
  end,
})
fulue:addEffect(fk.TargetSpecified, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and data.extra_data and data.extra_data.fulue_delay and
      data.extra_data.fulue_delay.to == player and data.extra_data.fulue_delay.from == data.to and
      not data.to:isNude() and not data.to.dead
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:addTableMarkIfNeed(data.to, "fulue-turn", "fulue_prey")
    local card = room:askToChooseCard(player, {
      target = data.to,
      flag = "he",
      skill_name = fulue.name,
    })
    room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, fulue.name, nil, false, player)
  end,
})

return fulue
