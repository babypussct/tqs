
local shoucheng = fk.CreateSkill{
  name = "shoucheng",
}

Fk:loadTranslationTable{
  ["shoucheng"] = "守成",
  [":shoucheng"] = "一名势力与你相同的角色于其回合外失去手牌后，若其没有手牌，你可以令其摸一张牌。",

  ["#shoucheng-draw"] = "守成：你可以令 %dest 摸一张牌",

  ["$shoucheng1"] = "待吾等助将军一臂之力！",
  ["$shoucheng2"] = "国库盈余，可助军威。",
}

local H = require "packages.hegemony.util"

shoucheng:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(shoucheng.name) then
      for _, move in ipairs(data) do
        if move.from and move.from:isKongcheng() and H.compareKingdomWith(move.from, player) and
          player.room:getCurrent() ~= move.from and not move.from.dead then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local targets = {}
    local room = player.room
    for _, move in ipairs(data) do
      if move.from and move.from:isKongcheng() and H.compareKingdomWith(move.from, player) and
        player.room:getCurrent() ~= move.from and not move.from.dead then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            table.insertIfNeed(targets, move.from)
          end
        end
      end
    end
    room:sortByAction(targets)
    for _, p in ipairs(targets) do
      if not player:hasSkill(shoucheng.name) then break end
      if p:isAlive() then
        event:setCostData(self, { tos = { p } })
        self:doCost(event, target, player, data)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local to = event:getCostData(self).tos[1]
    return player.room:askToSkillInvoke(player, {
      skill_name = shoucheng.name,
      prompt = "#shoucheng-draw::" .. to.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    event:getCostData(self).tos[1]:drawCards(1, shoucheng.name)
  end,
})

shoucheng:addAI(Fk.Ltk.AI.newInvokeStrategy{
  think = function(self, ai)
    local target = ai.room:getPlayerById(tonumber(string.split(ai.data[2], ":")[3]))
    return ai:getBenefitOfEvents(function(logic)
      logic:drawCards(target, 1, self.skill_name)
    end) >= 0
  end,
})

return shoucheng
