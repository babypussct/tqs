local xuanliu = fk.CreateSkill {
  name = "xuanliu",
}

Fk:loadTranslationTable{
  ["xuanliu"] = "旋流",
  [":xuanliu"] = "出牌阶段结束时，若你此阶段造成过伤害，你可以指定一名其他角色，其摸一张牌并可以使用一张手牌。若其使用的牌与你此阶段使用过的"..
  "牌牌名相同，其重复此流程，每回合每种牌名限因此重复一次。",

  ["#xuanliu-choose"] = "旋流：选择一名角色，其摸一张牌并使用一张牌，若使用你本阶段使用过的牌则重复此流程",
  ["#xuanliu-use"] = "旋流：你可以使用一张手牌，若使用 %src 本阶段使用过的牌则重复此流程",

  ["$xuanliu1"] = "辟之贤才，其涌如通流大川，当趋源头活水。",
  ["$xuanliu2"] = "玄岂以一己之私，而误忠良！",
}

xuanliu:addEffect(fk.EventPhaseEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xuanliu.name) and player.phase == Player.Play and
      #player.room.logic:getActualDamageEvents(1, function(e)
        return e.data.from == player
      end) > 0 and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = xuanliu.name,
      prompt = "#xuanliu-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]   ---@type ServerPlayer
    while not to.dead do
      to:drawCards(1, xuanliu.name)
      if to.dead or #to:getHandlyIds() == 0 then return end
      local use = room:askToPlayCard(to, {
        skill_name = xuanliu.name,
        prompt = "#xuanliu-use:"..player.id,
        cancelable = true,
        extra_data = {
          bypass_times = true,
          extraUse = true,
        },
      })
      if use == nil then return end
      if #room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local u = e.data
        if u.from == player and u.card.trueName == use.card.trueName and
          not table.contains(room:getBanner("xuanliu-turn") or {}, use.card.trueName) then
          return true
        end
      end, Player.HistoryPhase) > 0 then
        local banner = room:getBanner("xuanliu-turn") or {}
        table.insert(banner, use.card.trueName)
        room:setBanner("xuanliu-turn", banner)
      else
        break
      end
    end
  end,
})

return xuanliu
