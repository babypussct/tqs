
local lianpian = fk.CreateSkill {
  name = "nos_heg__lianpian",
}

Fk:loadTranslationTable {
  ["nos_heg__lianpian"] = "联翩",
  [":nos_heg__lianpian"] = "结束阶段，若你于此回合内弃置任意角色牌的总数大于你的体力值，你可以令一名与你势力相同的角色将手牌摸至体力上限。" ..
  "其他角色的结束阶段，若其于此回合内弃置任意角色牌的总数大于你的体力值，其可以弃置你的一张牌或令你回复1点体力。",

  ["#nos_heg__lianpian-draw"] = "联翩：你可以令一名同势力角色将手牌摸至体力上限",
  ["#nos_heg__lianpian-invoke"] = "联翩：你可以弃置 %src 的一张牌或令其回复1点体力",

  ["$nos_heg__lianpian1"] = "需持续投入，方有回报。",
  ["$nos_heg__lianpian2"] = "心无旁骛，断而敢行。",
}

local H = require "packages.hegemony.util"

lianpian:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(lianpian.name) and player.phase == Player.Finish and
      table.find(player.room:getAlivePlayers(false), function (p)
        return H.compareKingdomWith(player, p) and p:getHandcardNum() < p.maxHp
      end) then
      local num = 0
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.from and move.moveReason == fk.ReasonDiscard and move.proposer == player then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                num = num + 1
              end
            end
          end
        end
      end, Player.HistoryTurn)
      return num > player.hp
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getAlivePlayers(false), function (p)
      return H.compareKingdomWith(player, p) and p:getHandcardNum() < p.maxHp
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#nos_heg__lianpian-draw",
      skill_name = lianpian.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local to = event:getCostData(self).tos[1]
    to:drawCards(to.maxHp - to:getHandcardNum(), lianpian.name)
  end,
})

lianpian:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target ~= player and player:hasSkill(lianpian.name) and target.phase == Player.Finish and
      not target.dead and (not player:isNude() or player:isWounded()) then
      local num = 0
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.from and move.moveReason == fk.ReasonDiscard and move.proposer == target then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                num = num + 1
              end
            end
          end
        end
      end, Player.HistoryTurn)
      return num > player.hp
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    if not player:isNude() then
      table.insert(choices, "discard_card")
    end
    if player:isWounded() then
      table.insert(choices, "recover")
    end
    local choice = room:askToChoice(target, {
      choices = choices,
      skill_name = lianpian.name,
      prompt = "#nos_heg__lianpian-invoke:"..player.id,
      cancelable = true,
    })
    if choice ~= "Cancel" then
      room:doIndicate(target, { player })
      event:setCostData(self, { choice = choice })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    if choice == "discard_card" then
      local id = room:askToChooseCard(target, {
        target = player,
        flag = "he",
        skill_name = lianpian.name,
      })
      room:throwCard(id, lianpian.name, player, target)
    else
      room:recover{
        who = player,
        num = 1,
        recoverBy = target,
        skillName = lianpian.name,
      }
    end
  end,
})

return lianpian
