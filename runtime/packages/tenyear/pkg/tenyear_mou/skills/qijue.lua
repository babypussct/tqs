
local qijue = fk.CreateSkill {
  name = "qijue",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["qijue"] = "歧抉",
  [":qijue"] = "限定技，一名角色进入濒死状态时，你可以令回复2点体力并摸两张牌，然后将〖逐波〗的“造成”改为“受到”；"..
  "若该角色为你，〖逐波〗的时机修改为“你于回合外造成或受到伤害时”，并且不再需要失去体力。",

  ["#qijue-invoke"] = "歧抉：你可以令 %dest 回复2点体力并摸两张牌，你修改“逐波”",

  ["$qijue1"] = "",
  ["$qijue2"] = "",
}

qijue:addEffect(fk.AskForPeaches, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(qijue.name) and target.dying and
      player:usedSkillTimes(qijue.name, Player.HistoryGame) == 0
  end,
  on_cost = function (self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = qijue.name,
      prompt = "#qijue-invoke::"..target.id,
    }) then
      event:setCostData(self, { tos = { target } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:recover({
      who = target,
      num = 2,
      recoverBy = player,
      skillName = qijue.name
    })
    if not target.dead then
      target:drawCards(2, qijue.name)
    end
    if player:hasSkill("zhubo", true) then
      room:setPlayerMark(player, qijue.name, 1)
      if target == player then
        room:setPlayerMark(player, qijue.name, 2)
      end
    end
  end,
})

return qijue
