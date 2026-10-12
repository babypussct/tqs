
local liangyin = fk.CreateSkill {
  name = "m_ex__liangyin",
}

Fk:loadTranslationTable{
  ["m_ex__liangyin"] = "良姻",
  [":m_ex__liangyin"] = "当有牌被置于武将牌上时，你可以令一名角色摸一张牌；当任意角色获得一名角色武将牌上的牌时，你可以令一名角色弃置一张牌。"..
  "每轮结束时，你可以令本轮唯一成为〖良姻〗目标的角色回复1点体力，或令本轮唯一未成为〖良姻〗目标的角色失去1点体力。",

  ["#m_ex__liangyin-drawcard"] = "良姻：你可以令一名角色摸一张牌",
  ["#m_ex__liangyin-discard"] = "良姻：你可以令一名角色弃置一张牌",
  ["#m_ex__liangyin-hp"] = "良姻：你可以令目标角色回复或失去1点体力",

  ["@@m_ex__liangyin-round"] = "良姻",

  ["$m_ex__liangyin1"] = "愿作深山木，枝枝连理生。",
  ["$m_ex__liangyin2"] = "河汉清且浅，相去复几许。",
  ["$m_ex__liangyin3"] = "少年夫妻老来伴，执手相看两不厌。",
  ["$m_ex__liangyin4"] = "至高至明日月，至亲至疏夫妻。",
}

Fk:addTargetTip({
  name = liangyin.name,
  target_tip = function (self, player, to_select, selected, selected_cards, card, selectable, extra_data)
    if not selectable then return end
    if table.contains(player:getTableMark("m_ex__liangyin-round"), to_select) then
      return "heal_hp"
    else
      return "lose_hp"
    end
  end,
})

liangyin:addEffect(fk.AfterCardsMove, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(liangyin.name) then
      for _, move in ipairs(data) do
        if move.toArea == Card.PlayerSpecial then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea ~= Card.PlayerSpecial then
              return true
            end
          end
        end
        if move.toArea == Card.PlayerHand then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerSpecial then
              return table.find(player.room.alive_players, function(p)
                return not p:isNude()
              end)
            end
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local choices = {}
    for _, move in ipairs(data) do
      if move.toArea == Card.PlayerSpecial then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea ~= Card.PlayerSpecial then
            table.insertIfNeed(choices, "drawcard")
          end
        end
      end
      if move.toArea ~= Card.PlayerSpecial then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerSpecial then
            table.insertIfNeed(choices, "discard")
          end
        end
      end
    end
    for _, choice in ipairs(choices) do
      if player:hasSkill(liangyin.name) then
        if choice == "drawcard" or
          (choice == "discard" and table.find(player.room.alive_players, function(p)
            return not p:isNude()
          end)) then
          event:setCostData(self, { choice = choice })
          self:doCost(event, target, player, data)
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    local targets
    if choice == "drawcard" then
      targets = room.alive_players
    elseif choice == "discard" then
      targets = table.filter(room.alive_players, function(p)
        return not p:isNude()
      end)
    end
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = liangyin.name,
      prompt = "#m_ex__liangyin-"..choice,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to, choice = choice })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:addTableMarkIfNeed(player, "m_ex__liangyin-round", to)
    room:addPlayerMark(to, "@@m_ex__liangyin-round")
    local choice = event:getCostData(self).choice
    if choice == "drawcard" then
      room:notifySkillInvoked(player, liangyin.name, "support")
      player:broadcastSkillInvoke(liangyin.name)
      to:drawCards(1, liangyin.name)
    elseif choice == "discard" then
      room:notifySkillInvoked(player, liangyin.name, "control")
      player:broadcastSkillInvoke(liangyin.name)
      room:askToDiscard(to, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = liangyin.name,
        cancelable = false,
      })
    end
  end,
})

liangyin:addEffect(fk.RoundEnd, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(liangyin.name) then
      local targets = {}
      if #player:getTableMark("m_ex__liangyin-round") == 1 then
        local to = player:getTableMark("m_ex__liangyin-round")[1]
        if to:isWounded() and not to.dead then
          table.insert(targets, to)
        end
      end
      local tos = player.room:getAlivePlayers(false)
      for _, p in ipairs(player:getTableMark("m_ex__liangyin-round")) do
        table.removeOne(tos, p)
      end
      if #tos == 1 then
        table.insert(targets, tos[1])
      end
      if #targets > 0 then
        event:setCostData(self, { targets = targets })
        return true
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = event:getCostData(self).targets,
      skill_name = liangyin.name,
      prompt = "#m_ex__liangyin-hp",
      cancelable = true,
      target_tip_name = liangyin.name,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    if table.contains(player:getTableMark("m_ex__liangyin-round"), to) then
      room:recover{
        who = to,
        num = 1,
        recoverBy = player,
        skillName = liangyin.name,
      }
    else
      room:loseHp(to, 1, liangyin.name, player)
    end
  end,
})

return liangyin
