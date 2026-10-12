local shouhu = fk.CreateSkill {
  name = "shouhu",
}

Fk:loadTranslationTable {
  ["shouhu"] = "狩虎",
  [":shouhu"] = "出牌阶段限一次，你可以视为对一名其他角色使用一张【杀】，结算后本回合你计算与其距离+1。" ..
      "当其因此【杀】而进入濒死状态时，你摸体力上限张牌，且以此法获得的牌无次数限制；本阶段有角色进入你的攻击范围时此技能视为未发动过。",

  ["#shouhu"] = "狩虎：视为使用一张【杀】，结算后本回合你计算与其距离+1",
  ["@shouhu-turn-noclear"] = "狩虎",
  ["@@shouhu_buff-inhand"] = "狩虎",

  ["$shouhu1"] = "白驹踏云奔，蹄下虎骨碎千钧！",
  ["$shouhu2"] = "虓儿负勇力，狩虎何必看君王！",
}

shouhu:addEffect("viewas", {
  prompt = "#shouhu",
  pattern = "slash",
  filter_pattern = {
    min_num = 0,
    max_num = 0,
    pattern = "",
    subcards = {}
  },
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    local c = Fk:cloneCard("slash")
    c.skillName = shouhu.name
    return c
  end,
  before_use = function(self, player, use)
    use.extraUse = true
    use.extra_data = use.extra_data or {}
    use.extra_data.shouhuUser = player

    local room = player.room
    local targetsInAttackRange = table.filter(room.alive_players, function(p)
      return player:inMyAttackRange(p)
    end)

    if player:getMark("shouhu_targets-phase") == 0 then
      room:setPlayerMark(player, "shouhu_targets-phase", targetsInAttackRange)
    end
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(shouhu.name, Player.HistoryPhase) == 0
  end,
  enabled_at_response = Util.FalseFunc,
})

shouhu:addEffect(fk.EnterDying, {
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if not (data.damage and data.damage.card and player:isAlive()) then
      return false
    end
    local use = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    return use and player == (use.data.extra_data or {}).shouhuUser
  end,
  on_use = function(self, event, target, player, data)
    player.room:drawCards(player, player.maxHp, shouhu.name, "top", "@@shouhu_buff-inhand")
  end,
})

shouhu:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return data.card:getMark("@@shouhu_buff-inhand") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

shouhu:addEffect(fk.CardUseFinished, {
  is_delay_effect = true,
  mute = true,
  priority = 2,
  can_trigger = function(self, event, target, player, data)
    return player == (data.extra_data or {}).shouhuUser and player:hasSkill(shouhu.name) and target == player
  end,
  on_use = function(self, event, target, player, data)
    local tos = data.tos

    local room = player.room
    for _, to in ipairs(tos) do
      if to:isAlive() then
        room:addPlayerMark(to, "@shouhu-turn-noclear")
        local shouhuMapper = to:getTableMark("shouhu_mapper-turn-noclear")
        shouhuMapper[player] = (shouhuMapper[player] or 0) + 1
        room:setPlayerMark(to, "shouhu_mapper-turn-noclear", shouhuMapper)

        local targetsInAttackRange = table.filter(room.alive_players, function(p)
          return player:inMyAttackRange(p)
        end)
        room:setPlayerMark(player, "shouhu_targets-phase", targetsInAttackRange)
      end
    end
  end,
})

shouhu:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and (table.contains(card.skillNames, shouhu.name) or card:getMark("@@shouhu_buff-inhand") > 0)
  end,
})

shouhu:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return
        player:getMark("shouhu_targets-phase") ~= 0 and
        table.find(data, function(move)
          return
              (
                move.to == player and
                move.toArea == Card.PlayerEquip
              ) or
              (
                move.from == player and
                not not table.find(move.moveInfo, function(info)
                  return info.fromArea == Card.PlayerEquip
                end)
              )
        end)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local targetsInAttackRange = table.filter(room.alive_players, function(p)
      return player:inMyAttackRange(p)
    end)

    local preTargets = player:getTableMark("shouhu_targets-phase")
    if table.find(targetsInAttackRange, function(p) return not table.contains(preTargets, p) end) then
      player:clearSkillHistory(shouhu.name)
    end

    room:setPlayerMark(player, "shouhu_targets-phase", targetsInAttackRange)
  end,
})

shouhu:addEffect("distance", {
  correct_func = function(self, from, to)
    local record = to:getTableMark("shouhu_mapper-turn-noclear")[from]
    if record then
      return record
    end
  end,
})

return shouhu
