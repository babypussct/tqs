local sijian = fk.CreateSkill {
  name = "m_shi__sijian",
}

Fk:loadTranslationTable {
  ["m_shi__sijian"] = "死谏",
  [":m_shi__sijian"] = "每回合限两次，当你失去最后一张手牌后，或当你进入濒死状态时，你可以选择一项：" ..
      "1.选择一名其他角色，其使用下一张牌后需弃置一张牌；2.令当前回合角色摸两张牌。" ..
      "若此时没有角色处于濒死状态，你可以背水：失去X点体力（X为你发动此技能背水的次数）。",

  ["m_shi__sijian_discard"] = "令一名角色使用下一张牌后需弃一张牌",
  ["m_shi__sijian_draw"] = "%dest摸两张牌",
  ["m_shi__sijian_beishui"] = "背水：失去%arg点体力",
  ["#m_shi__sijian-choose"] = "死谏：令一名角色使用下一张牌后需弃一张牌",
  ["@m_shi__sijian"] = "死谏",

  ["$m_shi__sijian1"] = "若可劝得主公，丰死之无悔！",
  ["$m_shi__sijian2"] = "郁积于心，丰不吐不快！",
}

local spec = {
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    if #room:getOtherPlayers(player, false) > 0 then
      table.insert(choices, "m_shi__sijian_discard")
    end
    if room:getCurrent() and not room:getCurrent().dead then
      table.insert(choices, "m_shi__sijian_draw::" .. room:getCurrent().id)
    end
    if #choices == 2 and not table.find(room.alive_players, function(p)
          return p.dying
        end) then
      table.insert(choices, "m_shi__sijian_beishui:::" .. player:getMark(sijian.name))
    end
    table.insert(choices, "Cancel")
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = sijian.name,
      all_choices = {
        "m_shi__sijian_discard",
        "m_shi__sijian_draw::" .. room.current.id,
        "m_shi__sijian_beishui:::" .. player:getMark(sijian.name),
        "Cancel",
      },
    })
    if choice ~= "Cancel" then
      event:setCostData(self, { choice = choice })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    if choice:startsWith("m_shi__sijian_beishui") then
      room:addPlayerMark(player, sijian.name, 1)
      if player:getMark(sijian.name) > 1 then
        room:loseHp(player, player:getMark(sijian.name) - 1, sijian.name)
      end
    end
    if not choice:startsWith("m_shi__sijian_draw") and
        #room:getOtherPlayers(player, false) > 0 and not player.dead then
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = room:getOtherPlayers(player, false),
        skill_name = sijian.name,
        prompt = "#m_shi__sijian-choose",
        cancelable = false,
      })[1]
      room:addPlayerMark(to, "@m_shi__sijian", 1)
    end
    if choice ~= "m_shi__sijian_discard" and room:getCurrent() and not room:getCurrent().dead then
      room:getCurrent():drawCards(2, sijian.name)
    end
  end,
}

sijian:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(sijian.name) and player:isKongcheng() and
        player:usedSkillTimes(sijian.name, Player.HistoryTurn) < 2 and
        (#player.room:getOtherPlayers(player, false) > 0 or (player.room:getCurrent() and not player.room:getCurrent().dead)) then
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

sijian:addEffect(fk.EnterDying, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(sijian.name) and
        player:usedSkillTimes(sijian.name, Player.HistoryTurn) < 2 and
        (#player.room:getOtherPlayers(player, false) > 0 or (player.room:getCurrent() and not player.room:getCurrent().dead))
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

sijian:addEffect(fk.CardUsing, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@m_shi__sijian") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player:getMark("@m_shi__sijian")
    room:setPlayerMark(player, "@m_shi__sijian", 0)
    room:askToDiscard(player, {
      min_num = n,
      max_num = n,
      include_equip = true,
      skill_name = sijian.name,
      cancelable = false,
    })
  end,
})

return sijian
