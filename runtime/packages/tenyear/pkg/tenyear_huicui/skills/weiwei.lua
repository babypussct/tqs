local weiwei = fk.CreateSkill {
  name = "weiwei",
}

Fk:loadTranslationTable {
  ["weiwei"] = "维卫",
  [":weiwei"] = "每回合限一次，当你成为其他角色使用牌的目标后，你可以与其各摸两张牌，然后交换一张手牌，此牌结算后你可以使用其交给你的牌；" ..
      "若你交给其的牌此回合结束时仍在其手牌中，则你可以对其造成1点伤害。",

  ["#weiwei-invoke"] = "维卫：你可以和 %dest 各摸两张牌，然后交换一张手牌",
  ["#weiwei-swap"] = "维卫：请选择一张手牌与对方交换",
  ["@@weiwei-inhand-turn"] = "维卫",
  ["#weiwei-use"] = "维卫：你可以使用此牌",
  ["#weiwei-damage"] = "维卫：是否对 %dest 造成1点伤害？",

  ["$weiwei1"] = "交州虽远，亦在王土之滨。",
  ["$weiwei2"] = "九州六合，缺一不可！",
}

weiwei:addEffect(fk.TargetConfirmed, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(weiwei.name) and data.from ~= player and
        data.from:isAlive() and player:usedSkillTimes(weiwei.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
          skill_name = weiwei.name,
          "#weiwei-invoke::" .. data.from.id,
        }) then
      event:setCostData(self, { tos = { data.from } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = weiwei.name
    local room = player.room
    for _, p in ipairs({ player, data.from }) do
      if p:isAlive() then
        p:drawCards(2, skillName)
      end
    end

    if
        not (
          player:isAlive() and
          not player:isKongcheng() and
          data.from:isAlive() and
          not data.from:isKongcheng()
        )
    then
      return false
    end

    local result = room:askToJointCards(player, {
      min_num = 1,
      max_num = 1,
      players = { player, data.from },
      skill_name = skillName,
      cancelable = false,
      prompt = "#weiwei-swap",
    })
    room:swapCards(player, {
      { player,    result[player] },
      { data.from, result[data.from] },
    }, skillName)

    data.extra_data = data.extra_data or {}
    data.extra_data.weiweiUseCard = data.extra_data.weiweiUseCard or {}
    data.extra_data.weiweiUseCard[player] = result[data.from][1]
    room:setCardMark(Fk:getCardById(result[player][1]), "@@weiwei-inhand-turn", player.id)
  end,
})

weiwei:addEffect(fk.CardUseFinished, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not ((data.extra_data or {}).weiweiUseCard or {})[player] then
      return false
    end

    local cardId = data.extra_data.weiweiUseCard[player]
    return
        player:canUse(Fk:getCardById(cardId), { bypass_times = true, extraUse = true }) and
        table.find(player:getCardIds("h"), function(id) return id == cardId end)
  end,
  on_use = function(self, event, target, player, data)
    player.room:askToUseRealCard(player, {
      pattern = tostring(Exppattern { id = { data.extra_data.weiweiUseCard[player] } }),
      prompt = "#weiwei-use",
      skill_name = weiwei.name,
      cancelable = true,
      extra_data = {
        bypass_times = true,
        extraUse = true,
      }
    })
  end,
})

weiwei:addEffect(fk.TurnEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(weiwei.name) and
        table.find(target:getCardIds("h"), function(id)
          return Fk:getCardById(id):getMark("@@weiwei-inhand-turn") == player.id
        end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
          skill_name = weiwei.name,
          prompt = "#weiwei-damage::" .. target.id,
        }) then
      event:setCostData(self, { tos = { target } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:damage {
      from = player,
      to = target,
      damage = 1,
      skillName = weiwei.name,
    }
  end,
})

return weiwei
