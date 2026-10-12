
local shaowei = fk.CreateSkill{
  name = "shaowei",
  max_branches_use_time = {
    ["diamond"] = {
      [Player.HistoryTurn] = 1
    },
    ["heart"] = {
      [Player.HistoryTurn] = 1
    },
  },
}

Fk:loadTranslationTable{
  ["shaowei"] = "绍威",
  [":shaowei"] = "每回合各限一次，当你失去<font color='red'>♦</font>牌后，你摸两张牌；"..
  "当你失去<font color='red'>♥</font>牌后，你可以回复1点体力并恢复一个装备栏。",

  ["#shaowei-resume"] = "绍威：恢复一个装备栏",

  ["$shaowei1"] = "",
  ["$shaowei2"] = "",
}

shaowei:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(shaowei.name) and player:usedSkillTimes(shaowei.name, Player.HistoryTurn) < 2 then
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              if info.beforeCard.suit == Card.Diamond and shaowei:withinBranchTimesLimit(player, "diamond", Player.HistoryTurn) then
                return true
              end
              if info.beforeCard.suit == Card.Heart and shaowei:withinBranchTimesLimit(player, "heart", Player.HistoryTurn) and
                (player:isWounded() or table.find(player.sealedSlots, function (slot)
                  return slot ~= Player.JudgeSlot and slot ~= Player.HandSlot
                end)) then
                return true
              end
            end
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            if info.beforeCard.suit == Card.Diamond and shaowei:withinBranchTimesLimit(player, "diamond", Player.HistoryTurn) then
              table.insertIfNeed(choices, "diamond")
            end
            if info.beforeCard.suit == Card.Heart and shaowei:withinBranchTimesLimit(player, "heart", Player.HistoryTurn) and
              (player:isWounded() or table.find(player.sealedSlots, function (slot)
                return slot ~= Player.JudgeSlot and slot ~= Player.HandSlot
              end)) then
              table.insertIfNeed(choices, "heart")
            end
          end
          if #choices == 2 then break end
        end
      end
    end
    for _, choice in ipairs(choices) do
      if choice == "diamond" then
        player:addSkillBranchUseHistory(shaowei.name, "diamond", 1)
        --[[
        local cards = room:getCardsFromPileByRule(".|.|red", 3)
        if #cards > 0 then
          room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, shaowei.name, nil, false, player)
          if player.dead then return end
        end]]--
        player:drawCards(2, shaowei.name)
        if player.dead then return end
      else
        player:addSkillBranchUseHistory(shaowei.name, "heart", 1)
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = shaowei.name,
        }
        if player.dead then return end
        local slots = table.filter(player.sealedSlots, function (slot)
          return slot ~= Player.JudgeSlot and slot ~= Player.HandSlot
        end)
        if #slots > 0 then
          choice = room:askToChoice(player, {
            choices = slots,
            skill_name = shaowei.name,
            prompt = "#shaowei-resume",
          })
          room:resumePlayerArea(player, choice)
        end
      end
    end
  end,
})

return shaowei
