local jieli = fk.CreateSkill{
  name = "jielig",
}

Fk:loadTranslationTable{
  ["jielig"] = "解罹",
  [":jielig"] = "每轮限一次，当你成为一张牌的唯一目标时，你可以选择一项："..
    "1.由你重新选定此牌的目标；2.观看一名其他角色的所有手牌获得其中与此牌花色相同的牌。",

  ["jielig_changetarget"] = "重新选定此牌的目标",
  ["jielig_viewhandcard"] = "观看一名角色的手牌",
  ["#jielig-changetarget"] = "解罹：请为 %arg 重新选择目标",
  ["#jielig-viewhandcard"] = "解罹：选择一名其他角色，观看其所有手牌并获得其中的%arg牌",

  ["$jielig1"] = "",
  ["$jielig2"] = "",
}

jieli:addEffect(fk.TargetConfirming, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return
      player == target and
      not data.cancelled and
      #data.use.tos == 1 and
      data.card.type ~= Card.TypeEquip and
      player:hasSkill(jieli.name) and
      player:usedSkillTimes(jieli.name, Player.HistoryRound) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local skillName = jieli.name
    local room = player.room
    local tos1 = {}
    local sub_tos = data.subTargets
    local extra_data = {}
    for _, p in ipairs(room.alive_players) do
      if not data.from:isProhibited(p, data.card) and
        data.card.skill:modTargetFilter(data.from, p, {}, data.card, extra_data) then
        if sub_tos and #sub_tos > 0 then
          local mod_tos = { p }
          if table.every(sub_tos, function(sub_to)
            if data.card.skill:modTargetFilter(data.from, sub_to, mod_tos, data.card, extra_data) then
              table.insert(mod_tos, sub_to)
              return true
            end
          end) then
            table.insert(tos1, p)
          end
        else
          table.insert(tos1, p)
        end
      end
    end

    local all_choices = { "jielig_changetarget", "jielig_viewhandcard", "Cancel" }
    local choices = { "Cancel" }
    if #tos1 > 0 then
      table.insert(choices, all_choices[1])
    end
    local tos2 = table.filter(room.alive_players, function(p)
      return p ~= player and p:getHandcardNum() > 0
    end)
    if #tos2 > 0 then
      table.insert(choices, all_choices[2])
    end

    local choice = room:askToChoice(player, {
      choices = choices,
      all_choices = all_choices,
      skill_name = skillName,
    })

    if choice == "Cancel" then
      return
    end

    local params = {
      min_num = 1,
      max_num = 1,
      targets = tos1,
      skill_name = skillName,
      prompt = "#jielig-changetarget:::" .. data.card:toLogString(),
      cancelable = true,
    }
    if choice == "jielig_viewhandcard" then
      params.targets = tos2
      params.prompt = "#jielig-viewhandcard:::" .. data.card:getSuitString(true)
    end

    local targets = room:askToChoosePlayers(player, params)

    if #targets > 0 then
      event:setCostData(self, { tos = targets, choice = choice })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local skillName = jieli.name
    local to = event:getCostData(self).tos[1]
    if event:getCostData(self).choice == "jielig_changetarget" then
      if data.to ~= to and data:cancelCurrentTarget() then
        data:addTarget(to, nil, true)
      end
    else
      local room = player.room
      local cards = to:getCardIds("h")
      room:viewCards(player, { cards = cards, skill_name = skillName, prompt = "$ViewCardsFrom:" .. to.id })
      local suit = data.card.suit
      if suit ~= Card.NoSuit then
        cards = table.filter(cards, function(id)
          return Fk:getCardById(id).suit == suit
        end)
        if #cards > 0 then
          room:obtainCard(player, cards, false, fk.ReasonPrey, player, skillName)
        end
      end
    end
  end,
})

return jieli
