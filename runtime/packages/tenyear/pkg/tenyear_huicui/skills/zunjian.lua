local zunjian = fk.CreateSkill {
  name = "zunjian",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["zunjian"] = "遵谏",
  [":zunjian"] = "觉醒技，回合开始时，若你已移除〖漠规〗所有选项，你回复1点体力并选择一项："..
  "1.摸两张牌并重置〖漠规〗；2.再回复1点体力，然后失去〖漠规〗并<a href=':rencheng_upgrade'>修改〖仁诚〗</a>。",

  ["zunjian_reset"] = "摸两张牌并重置“漠规”",
  ["zunjian_lose"] = "失去“漠规”，修改“仁诚”，回复1点体力",

  ["$zunjian1"] = "孤非桀纣，不敢讳诸师之言。",
  ["$zunjian2"] = "开张纳言之听，不宜引喻失义。",
}

zunjian:addEffect(fk.TurnStart, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zunjian.name) and
      player:usedSkillTimes(zunjian.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:hasSkill("mogui", true) and #player:getTableMark("mogui_used") == 3
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local skillName = zunjian.name
    if player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = skillName
      }
      if player.dead then return end
    end
    if room:askToChoice(player, {
      choices = { "zunjian_reset", "zunjian_lose" },
      skill_name = skillName,
    }) == "zunjian_reset" then
      room:setPlayerMark(player, "mogui_used", {})
      player:drawCards(2, skillName)
    else
      --实测先失去技能再回复体力
      room:handleAddLoseSkills(player, "-mogui")
      room:setPlayerMark(player, "rencheng_upgrade", 1)
      if player:isWounded() then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = skillName
        }
      end
    end
  end,
})

return zunjian
