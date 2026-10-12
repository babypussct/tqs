
local haoxue = fk.CreateSkill {
  name = "haoxue",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["haoxue"] = "好学",
  [":haoxue"] = "锁定技，你于：出牌阶段外弃置牌时，失去1点体力；出牌阶段内获得牌时，回复1点体力。",

  ["$haoxue1"] = "悔吾见事之晚，未知治学之要。",
  ["$haoxue2"] = "因公废读，实吾愚钝未开啊。",
  ["$haoxue3"] = "五年征战，三年勤学，方为大将之才。",
  ["$haoxue4"] = "开卷有益，主公所言甚是啊。",
}

haoxue:addEffect(fk.AfterCardsMove, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(haoxue.name) then
      if player.phase ~= Player.Play then
        for _, move in ipairs(data) do
          if move.from == player and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                return true
              end
            end
          end
        end
      elseif player:isWounded() then
        for _, move in ipairs(data) do
          if move.to == player and move.toArea == Card.PlayerHand then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.phase ~= Player.Play then
      player:broadcastSkillInvoke(haoxue.name, table.random { 1, 2 })
      room:notifySkillInvoked(player, haoxue.name, "negative")
      room:loseHp(player, 1, haoxue.name, player)
    else
      player:broadcastSkillInvoke(haoxue.name, table.random { 3, 4 })
      room:notifySkillInvoked(player, haoxue.name, "support")
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = haoxue.name,
      }
    end
  end,
})

return haoxue
