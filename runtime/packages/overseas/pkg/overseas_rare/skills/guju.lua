local osGuju = fk.CreateSkill {
  name = "os__guju",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__guju"] = "骨疽",
  [":os__guju"] = "锁定技，当有“傀”的角色受到伤害后，你摸一张牌。",

  ["@os__guju"] = "骨疽",
  ["os__bingzhao_draw"] = "令其额外摸一张牌",
  ["#os__bingzhao-ask"] = "秉诏：是否令 %src 额外摸一张牌？",

  ["$os__guju1"] = "你还没有见过真正的恐惧。",
  ["$os__guju2"] = "这些，你就感到害怕了吗？"
}

osGuju:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player, data)
    return target:getMark("@@os__puppet") > 0 and player:hasSkill(osGuju.name) and target:isAlive()
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osGuju.name
    local num = 1
    local room = player.room
    if target.kingdom == player:getMark("@os__bingzhao") and player:hasSkill("os__bingzhao") then
      if room:askToChoice(target, {
        choices = { "os__bingzhao_draw", "Cancel" },
        skill_name = skillName,
        prompt = "#os__bingzhao-ask:" .. player.id
      }) ~= "Cancel" then
        num = 2
      end
    end
    player:drawCards(num, skillName)
    room:addPlayerMark(player, skillName, num)
    if player:usedSkillTimes("os__baijia", Player.HistoryGame) == 0 then
      room:addPlayerMark(player, "@" .. skillName, num)
    end
  end,
})

osGuju:addLoseEffect(function(self, player, is_death)
  player.room:setPlayerMark(player, "@" .. osGuju.name, 0)
end)

return osGuju
