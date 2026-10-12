

local chengxi = fk.CreateSkill{
  name = "heg__chengxi",
}

Fk:loadTranslationTable{
  ["heg__chengxi"] = "乘隙",
  [":heg__chengxi"] = "准备阶段，你可以令一名角色视为使用一张【以逸待劳】，结算结束后，若因此【以逸待劳】弃置的牌中包含非基本牌，"..
  "此【以逸待劳】的使用者对目标各造成1点伤害。",

  ["#heg__chengxi-choose"] = "乘隙：令一名角色视为使用【以逸待劳】，若因此弃置非基本牌，则所有目标受到伤害",

  ["$heg__chengxi1"] = "考其遗法，肃若神明。",
  ["$heg__chengxi2"] = "气韵生动，出于天成。",
}

local H = require "packages.hegemony.util"

chengxi:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chengxi.name) and player.phase == Player.Start and
      table.find(player.room.alive_players, function (p)
        return not p:prohibitUse(Fk:cloneCard("await_exhausted"))
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
        return not p:prohibitUse(Fk:cloneCard("await_exhausted"))
      end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = chengxi.name,
      prompt = "#heg__chengxi-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local targets = table.filter(room:getAlivePlayers(), function(p)
      return H.compareKingdomWith(p, to)
    end)
    local use = room:useVirtualCard("await_exhausted", nil, to, targets, chengxi.name)
    if use and use.extra_data and use.extra_data.heg__chengxi then
      room:sortByAction(use.tos)
      for _, p in ipairs(use.tos) do
        if not p.dead then
          room:damage{
            from = use.from,
            to = p,
            damage = 1,
            skillName = chengxi.name,
          }
        end
      end
    end
  end,
})

chengxi:addEffect(fk.AfterCardsMove, {
  can_refresh = function (self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.skillName == "await_exhausted" and move.moveReason == fk.ReasonDiscard then
        local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
        return use_event and use_event.data.card.skillName == chengxi.name
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.skillName == "await_exhausted" and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).type ~= Card.TypeBasic then
            local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
            if use_event then
              use_event.data.extra_data = use_event.data.extra_data or {}
              use_event.data.extra_data.heg__chengxi = true
            end
          end
        end
      end
    end
  end,
})

return chengxi
