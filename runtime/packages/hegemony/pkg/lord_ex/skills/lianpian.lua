local lianpian = fk.CreateSkill {
  name = "ld__lianpian",
}

Fk:loadTranslationTable {
  ["ld__lianpian"] = "联翩",
  [":ld__lianpian"] = "结束阶段，若你于此回合内弃置任意角色牌的总数大于你的体力值，你可以令一名与你势力相同的角色将手牌摸至体力上限。" ..
      "其他角色的结束阶段，若其于此回合内弃置任意角色牌的总数大于你的体力值，其可以弃置你的一张牌或令你回复1点体力。",

  ["@ld__lianpian-record-turn"] = "联翩",
  ["#ld__lianpian-ask"] = "联翩：是否发动",
  ["ld__lianpian-discard"] = "联翩：选择 %src 的一张牌弃置",
  ["#ld__lianpian_discard"] = "联翩：弃置 %src 的一张牌",
  ["ld__lianpian_recoverHp"] = "联翩：令 %src 回复1点体力",
  ["#ld__lianpian-choose"] = "联翩：选择一名与你势力相同的角色，令其将手牌摸至体力上限。",

  ["$ld__lianpian1"] = "需持续投入，方有回报。",
  ["$ld__lianpian2"] = "心无旁骛，断而敢行。",
}

local H = require "packages.hegemony.util"

lianpian:addEffect(fk.EventPhaseStart, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if not (player.phase == Player.Finish and player:hasSkill(lianpian.name)) then return false end
    local num = 0
    player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move and move.from and ((move.to and move.to ~= player) or not table.contains({ Card.PlayerHand, Card.PlayerEquip }, move.toArea))
            and move.moveReason == fk.ReasonDiscard and move.proposer == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              num = num + 1
            end
          end
        end
      end
      return false
    end, Player.HistoryTurn)
    return num > player.hp
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p) return H.compareKingdomWith(p, player) end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#ld__lianpian-choose",
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
    local num = to.maxHp - to:getHandcardNum()
    if num > 0 then
      to:drawCards(num, lianpian.name)
    end
  end,
})

lianpian:addEffect(fk.EventPhaseStart, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    if target == player or not (target.phase == Player.Finish and player:hasSkill(lianpian.name)) then return false end
    if target ~= player and player:hasShownSkill(lianpian.name) then
      local num = 0
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move and move.from and ((move.to and move.to ~= target) or not table.contains({ Card.PlayerHand, Card.PlayerEquip }, move.toArea))
              and move.moveReason == fk.ReasonDiscard and move.proposer == target then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                num = num + 1
              end
            end
          end
        end
        return false
      end, Player.HistoryTurn)
      return num > player.hp
    end
  end,
  on_cost = function(self, event, target, player, data)
    return target.room:askToSkillInvoke(target, { skill_name = lianpian.name, prompt = "#ld__lianpian-ask" })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    table.insert(choices, "ld__lianpian-discard:" .. player.id)
    if player:isWounded() then
      table.insert(choices, "ld__lianpian_recoverHp:" .. player.id)
    end
    local choice = room:askToChoice(target, { choices = choices, skill_name = lianpian.name })
    if choice == "ld__lianpian-discard:" .. player.id then
      if not player:isNude() then
        local id = room:askToChooseCard(target, {
          target = player,
          flag = "he",
          skill_name = lianpian.name,
          prompt = "#ld__lianpian_discard:" .. player.id,
        })
        room:throwCard({ id }, lianpian.name, player, target)
      end
    else
      room:recover({
        who = player,
        num = 1,
        recoverBy = target,
        skillName = lianpian.name
      })
    end
  end,
})

return lianpian
