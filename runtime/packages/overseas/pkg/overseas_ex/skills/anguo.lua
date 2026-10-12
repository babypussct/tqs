local anguo = fk.CreateSkill {
  name = "os_ex__anguo",
}

local U = require "packages.utility.utility"

Fk:loadTranslationTable{
  ["os_ex__anguo"] = "安国",
  [":os_ex__anguo"] = "游戏的首个回合结束时，你令一名其他角色获得“安国”。拥有“安国”的角色拥有以下效果：" ..
    "1.摸牌阶段多摸一张牌；2.手牌上限等于其体力上限。" ..
    "出牌阶段开始时，你可以将“安国”移动给另一名其他角色。" ..
    "出牌阶段限一次，若拥有“安国”的角色已受伤，你可以摸X张牌，然后交给其等量张牌。（X为其已损失的体力值且最大为2）" ..
    "当你或拥有“安国”的角色进入濒死状态时，你可以移除“安国”的一项效果，令濒死角色将体力回复至1点。",

  ["@os_ex__anguo"] = "安国",
  ["@os_ex__anguo_target"] = "安国",
  ["#os_ex__anguo-give"] = "安国：选择一名其他角色，令其获得“安国”标记",
  ["#os_ex__anguo-transfer"] = "安国：你可将“安国”移动给除 %dest 外的一名其他角色",
  ["#os_ex__anguo-active"] = "你可发动 安国，摸 %arg 张牌，然后交给 %dest %arg 张牌",
  ["#os_ex__anguo-give_card"] = "安国：交给 %dest %arg 张牌",
  ["#os_ex__anguo_remove"] = "安国：移除“安国”的一项效果，令%dest将体力回复至1点",
  ["os_ex__anguo_draw"] = "摸牌阶段多摸一张牌",
  ["os_ex__anguo_maxcards"] = "手牌上限等于其体力上限",

  ["$os_ex__anguo1"] = "臣以为如此，可保社稷无虞。",
  ["$os_ex__anguo2"] = "文可匡君辅国，武当以战安邦！",
}

anguo:addEffect("active", {
  anim_type = "support",
  prompt = function (self, player, selected_cards, selected_targets)
    return "#os_ex__anguo-active::" .. player:getMark("@os_ex__anguo_target").id .. ":" ..
      math.min(2, player:getMark("@os_ex__anguo_target"):getLostHp())
  end,
  can_use = function (self, player)
    return player:usedEffectTimes(self.name, Player.HistoryPhase) == 0 and
      player:getMark("@os_ex__anguo_target") ~= 0 and
      player:getMark("@os_ex__anguo_target"):isWounded()
  end,
  card_filter = Util.FalseFunc,
  card_num = 0,
  target_num = 0,
  on_use = function (self, room, skillUseEvent)
    local player = skillUseEvent.from
    local to = player:getMark("@os_ex__anguo_target")
    local num = math.min(2, to:getLostHp())
    player:drawCards(num, anguo.name)
    if player:isAlive() and to:isAlive() and not player:isNude() then
      local card = room:askToCards(player, {
        min_num = num,
        max_num = num,
        include_equip = true,
        skill_name = anguo.name,
        cancelable = false,
        prompt = "#os_ex__anguo-give_card::" .. to.id .. ":" .. num,
      })
      if #card > 0 then
        room:moveCardTo(card, Card.PlayerHand, to, fk.ReasonGive, anguo.name, nil, false, player)
      end
    end
  end
})

anguo:addEffect(fk.TurnEnd, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(anguo.name) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
      player.room.logic:getEventsOfScope(GameEvent.Turn, 1, function(e)
        return true
      end, Player.HistoryGame)[1].id == player.room.logic:getCurrentEvent().id and #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#os_ex__anguo-give",
      skill_name = anguo.name,
      cancelable = false,
    })
    event:setCostData(self, {tos = to})
    return true
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:setPlayerMark(to, "@os_ex__anguo", {1, 2})
    room:setPlayerMark(player, "@os_ex__anguo_target", to)
  end
})

anguo:addEffect(fk.DrawNCards, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and table.contains(player:getTableMark("@os_ex__anguo"), 1)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    data.n = data.n + 1
  end
})

anguo:addEffect("maxcards", {
  fixed_func = function(self, player)
    if table.contains(player:getTableMark("@os_ex__anguo"), 2) then
      return player.maxHp
    end
  end
})

anguo:addEffect(fk.EventPhaseStart, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(anguo.name) and
      player:getMark("@os_ex__anguo_target") ~= 0 and target.phase == Player.Play
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = room:getOtherPlayers(player, false)
    table.removeOne(targets, player:getMark("@os_ex__anguo_target"))
    if #targets == 0 then
      return false
    end
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#os_ex__anguo-transfer::" .. player:getMark("@os_ex__anguo_target").id,
      skill_name = anguo.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local orig = player:getMark("@os_ex__anguo_target")
    local record = orig:getTableMark("@os_ex__anguo")
    room:setPlayerMark(orig, "@os_ex__anguo", 0)
    room:setPlayerMark(to, "@os_ex__anguo", record)
    room:setPlayerMark(player, "@os_ex__anguo_target", to)
  end
})

anguo:addEffect(fk.EnterDying, {
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(anguo.name) and player:getMark("@os_ex__anguo_target") ~= 0 and
      (target == player or target == player:getMark("@os_ex__anguo_target"))
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = player:getMark("@os_ex__anguo_target")
    local record = to:getTableMark("@os_ex__anguo")
    local all_choices = {"os_ex__anguo_draw", "os_ex__anguo_maxcards"}
    local choices = {}
    for _, j in ipairs(record) do
      table.insert(choices, all_choices[j])
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      all_choices = all_choices,
      skill_name = anguo.name,
      prompt = "#os_ex__anguo_remove::" .. target.id,
    })
    table.removeOne(record, table.indexOf(all_choices, choice))
    if #record == 0 then
      record = 0
      room:setPlayerMark(player, "@os_ex__anguo_target", 0)
    end
    room:setPlayerMark(to, "@os_ex__anguo", record)
    local n = 1 - target.hp
    room:recover{
      who = target,
      num = n,
      skillName = anguo.name,
      recoverBy = player,
    }
  end
})

anguo:addEffect(fk.BuryVictim, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("@os_ex__anguo") ~= 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      if p:getMark("@os_ex__anguo_target") == target then
        room:setPlayerMark(p, "@os_ex__anguo_target", 0)
      end
    end
  end
})

anguo:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@os_ex__anguo_target", 0)
end)

return anguo
