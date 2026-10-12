local shengxi = fk.CreateSkill {
  name = "os__shengxi",
}

Fk:loadTranslationTable{
  ["os__shengxi"] = "生息",
  [":os__shengxi"] = "准备阶段，你可以获得一张<a href=':redistribute'>【调剂盐梅】</a>。结束阶段，若你于此回合内使用过牌且没有造成过伤害，"..
  "你可以从牌堆中获得一张你指定的<a href='bag_of_tricks'>智囊</a>并摸一张牌。",

  ["#os__shengxi-invoke"] = "生息：你可以获得一张指定的“智囊”并摸一张牌",

  ["$os__shengxi1"] = "利治小之宜，秉居静之理。",
  ["$os__shengxi2"] = "外却骆谷之师，内保宁缉之实。",
}

local U = require "packages.utility.utility"

local shengxi_derivecards = {
  {"redistribute", Card.Spade, 6},
  {"redistribute", Card.Heart, 6},
  {"redistribute", Card.Club, 6},
  {"redistribute", Card.Diamond, 6},
}

shengxi:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(shengxi.name) then
      if player.phase == Player.Start then
        return true
      elseif player.phase == Player.Finish then
        return #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
          return e.data.from == player
        end, Player.HistoryTurn) > 0 and
        #player.room.logic:getActualDamageEvents(1, function(e)
          return e.data.from == player
        end, Player.HistoryTurn) == 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if player.phase == Player.Start then
      return player.room:askToSkillInvoke(player, {
        skill_name = shengxi.name,
      })
    else
      local choice = player.room:askToChoice(player, {
        choices = {"dismantlement", "nullification", "ex_nihilo", "Cancel"},
        skill_name = shengxi.name,
        prompt = "#os__shengxi-invoke",
      })
      if choice ~= "Cancel" then
        event:setCostData(self, {choice = choice})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.phase == Player.Start then
      local cids = table.filter(room:prepareDeriveCards(shengxi_derivecards, shengxi.name), function (id)
        return room:getCardArea(id) == Card.Void
      end)
      if #cids == 0 then
        cids = table.filter(room:prepareDeriveCards(shengxi_derivecards, shengxi.name), function (id)
          return table.contains(room.draw_pile, id)
        end)
      end
      if #cids > 0 then
        room:obtainCard(player, room:tableRandomPick(cids), false, fk.ReasonJustMove, player, shengxi.name)
      end
    else
      local id = room:getCardsFromPileByRule(event:getCostData(self).choice)
      if #id > 0 then
        room:obtainCard(player, id, false, fk.ReasonJustMove, player, shengxi.name)
      end
      if player.dead then return end
      player:drawCards(1, shengxi.name)
    end
  end,
})

return shengxi
