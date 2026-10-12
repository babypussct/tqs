local mobileXushen = fk.CreateSkill {
  name = "mobile__xushen",
  tags = { Skill.Limited },
  related_skills = { "wusheng", "dangxian", "zhiman" },
}

Fk:loadTranslationTable{
  ["mobile__xushen"] = "许身",
  [":mobile__xushen"] = "限定技，出牌阶段，你可以摸至多三张牌并失去等量体力。若你因此进入濒死状态，则你脱离濒死状态后，" ..
  "你可以将〖武圣〗〖当先〗〖制蛮〗分配给本次濒死结算中令你回复过体力的角色（若其已拥有对应技能则摸三张牌）。",

  ["#mobile__xushen-choose"] = "许身：你可以令其中一名角色获得“%arg”",

  ["$mobile__xushen1"] = "你我相遇于此，应当彼此珍惜。",
  ["$mobile__xushen2"] = "携子之手，与子共闯天涯。",
}

mobileXushen:addEffect("active", {
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  interaction = function(self, player)
    return UI.Spin {
      from = 1,
      to = 3,
    }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(mobileXushen.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local n = self.interaction.data
    player:drawCards(n, mobileXushen.name)
    room:loseHp(player, n, mobileXushen.name)
  end,
})

mobileXushen:addEffect(fk.AfterDying, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:isAlive() and data.extra_data and data.extra_data.mobile__xushen
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(data.extra_data.mobile__xushen, function(p) return p:isAlive() end)
    if #targets == 0 then
      return false
    end

    for _, skillName in ipairs({ "wusheng", "dangxian", "zhiman" }) do
      local tos = room:askToChoosePlayers(
        player,
        {
          min_num = 1,
          max_num = 1,
          targets = targets,
          skill_name = mobileXushen.name,
          prompt = "#mobile__xushen-choose:::" .. skillName,
        }
      )
      if #tos > 0 then
        local to = tos[1]
        room:doIndicate(player, { to })
        if to:hasSkill(skillName, true) then
          to:drawCards(3, mobileXushen.name)
        else
          room:handleAddLoseSkills(to, skillName)
        end
      end
    end
  end,
})

mobileXushen:addEffect(fk.HpChanged, {
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
        if skillName == "mobile__xushen" then
          local dying_event = room.logic:getCurrentEvent():findParent(GameEvent.Dying)
          if dying_event then
            local dying = dying_event.data
            dying.extra_data = dying.extra_data or {}
            dying.extra_data.mobile__xushen = dying.extra_data.mobile__xushen or {}
            table.insertIfNeed(dying.extra_data.mobile__xushen, dat.recoverBy)
          end
        end
      end
    end
  end,
})

return mobileXushen
