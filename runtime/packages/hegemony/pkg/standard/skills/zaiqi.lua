local zaiqi = fk.CreateSkill{
  name = "hs__zaiqi",
}

Fk:loadTranslationTable {
  ["hs__zaiqi"] = "再起",
  [":hs__zaiqi"] = "弃牌阶段结束时，你可以令至多X名与你势力相同的角色依次选择一项（X为本回合进入弃牌堆的<font color='red'>♥</font>牌数）："..
  "1.摸一张牌；2.令你回复1点体力。",

  ["#hs__zaiqi-choose"] = "再起：选择至多%arg名角色，这些角色各选择令你回复1点体力或摸一张牌",
  ["hs__zaiqi_recover"] = "%src回复1点体力",

  ["$hs__zaiqi1"] = "丞相助我！",
  ["$hs__zaiqi2"] = "起！",
}

local H = require "packages.hegemony.util"

zaiqi:addEffect(fk.EventPhaseEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(zaiqi.name) and player.phase == Player.Discard then
      local ids = {}
      local room = player.room
      room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              table.insertIfNeed(ids, info.cardId)
            end
          end
        end
      end, Player.HistoryTurn)
      local x = #table.filter(ids, function (id)
        return Fk:getCardById(id).suit == Card.Heart
      end)
      if x > 0 then
        event:setCostData(self, { extra_data = x })
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local x = event:getCostData(self).extra_data
    local targets = table.filter(room.alive_players, function (p)
      return H.compareExpectedKingdomWith(player, p)
    end)
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = x,
      prompt = "#hs__zaiqi-choose:::"..x,
      skill_name = zaiqi.name,
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = event:getCostData(self).tos or {}
    for _, p in ipairs(targets) do
      if not p.dead then
        local choices = { "draw1" }
        if not player.dead and player:isWounded() then
          table.insert(choices, "hs__zaiqi_recover:"..player.id)
        end
        local choice = room:askToChoice(p, {
          choices = choices,
          skill_name = zaiqi.name,
        })
        if choice == "draw1" then
          p:drawCards(1, zaiqi.name)
        else
          room:recover{
            who = player,
            num = 1,
            recoverBy = p,
            skillName = zaiqi.name,
          }
        end
      end
    end
  end,
})

return zaiqi