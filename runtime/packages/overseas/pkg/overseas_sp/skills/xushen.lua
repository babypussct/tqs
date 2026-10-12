local xushen = fk.CreateSkill {
  name = "os__xushen",
  tags = { Skill.Limited },
  related_skills = { "os__wushen", "m_ex__dangxian", "ty_ex__zhiman" }
}

Fk:loadTranslationTable{
  ["os__xushen"] = "许身",
  [":os__xushen"] = "限定技，每轮开始时或出牌阶段，你可以摸至多四张牌并失去等量体力。若你因此进入濒死状态，则你脱离濒死状态后，" ..
  "你可以将〖武神〗、〖当先〗、〖制蛮〗分配给本次濒死结算中令你回复过体力的角色，" ..
  "（若其已拥有对应技能则摸三张牌）。",

  ["#os__xushen-active"] = "许身：可以摸至多四张牌并失去等量体力",
  ["#os__xushen-round"] = "是否发动“许身”？",
  ["#os__xushen-choose"] = "许身：你可以令其中一名角色获得“%arg”",

  ["$os__xushen1"] = "承蒙将军相救，妾身感激不已。",
  ["$os__xushen2"] = "若非将军及时赶到，妾身性命难保。",
  ["$os__wushen_os__baosanniang"] = "吾等当效，关将军之神勇。",
  ["$m_ex__dangxian_os__baosanniang"] = "逆贼，休得狂言！",
  ["$ty_ex__zhiman_os__baosanniang"] = "以武立威，何如以文教化。",
}

xushen:addEffect("active", {
  prompt = "#os__xushen-active",
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  interaction = UI.Spin {
    from = 1,
    to = 4,
  },
  can_use = function(self, player)
    return player:usedSkillTimes(xushen.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local n = self.interaction.data
    player:drawCards(n, xushen.name)
    if player:isAlive() then
      room:loseHp(player, n, xushen.name)
    end
  end,
})

xushen:addEffect(fk.RoundStart, {
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(xushen.name) and player:usedSkillTimes(xushen.name, Player.HistoryGame) == 0
  end,
  on_cost = function (self, event, target, player, data)
    local use, dat = player.room:askToUseActiveSkill(player, {
      skill_name = "os__xushen",
      cancelable = true,
      skip = true,
      prompt = "#os__xushen-round",
    })
    if use and dat then
      event:setCostData(self, { num = dat.interaction })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local n = event:getCostData(self).num
    player:drawCards(n, xushen.name)
    if player:isAlive() then
      player.room:loseHp(player, n, xushen.name)
    end
  end
})

xushen:addEffect(fk.AfterDying, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:isAlive() and data.extra_data and data.extra_data.os__xushen
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(data.extra_data.os__xushen, function(p) return p:isAlive() end)
    if #targets == 0 then
      return false
    end

    for _, skillName in ipairs{ "os__wushen", "m_ex__dangxian", "ty_ex__zhiman" } do
      local tos = room:askToChoosePlayers(
        player,
        {
          min_num = 1,
          max_num = 1,
          targets = targets,
          skill_name = xushen.name,
          prompt = "#os__xushen-choose:::" .. skillName,
        }
      )
      if #tos > 0 then
        local to = tos[1]
        room:doIndicate(player, { to })
        if to:hasSkill(skillName, true) then
          to:drawCards(3, xushen.name)
        else
          room:handleAddLoseSkills(to, skillName)
        end
      end
    end
  end,
})

xushen:addEffect(fk.HpChanged, {
  can_refresh = function (self, event, target, player, data)
    return player == target and data.num > 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local recover_event = room.logic:getCurrentEvent():findParent(GameEvent.Recover)
    if recover_event then
      local dat = recover_event.data
      if dat.recoverBy then
        local hpchange_event = room.logic:getCurrentEvent():findParent(GameEvent.ChangeHp, false)
        local skillName = hpchange_event and hpchange_event.data.skillName
        if skillName == "os__xushen" then
          local dying_event = room.logic:getCurrentEvent():findParent(GameEvent.Dying)
          if dying_event then
            local dying = dying_event.data
            dying.extra_data = dying.extra_data or {}
            dying.extra_data.os__xushen = dying.extra_data.os__xushen or {}
            table.insertIfNeed(dying.extra_data.os__xushen, dat.recoverBy)
          end
        end
      end
    end
  end,
})

return xushen
