
local zili = fk.CreateSkill {
  name = "ol_ex__zili",
  tags = { Skill.Wake },
  related_skills = { "ol_ex__paiyi" },
}

Fk:loadTranslationTable{
  ["ol_ex__zili"] = "自立",
  [":ol_ex__zili"] = "觉醒技，每个准备阶段，若你“权”的数量大于等于3，你回复1点体力或摸两张牌，然后减少1点体力上限，获得〖排异〗。",

  ["$ol_ex__zili1"] = "",
  ["$ol_ex__zili2"] = ""
}

zili:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zili.name) and
      target.phase == Player.Start and
      player:usedSkillTimes(zili.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #player:getPile("zhonghui_quan") > 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = { "draw2" }
    if player:isWounded() then
      table.insert(choices, "recover")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = zili.name
    })
    if choice == "draw2" then
      player:drawCards(2, zili.name)
    else
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = zili.name,
      }
    end
    if player.dead then return end
    room:changeMaxHp(player, -1)
    if player.dead then return end
    room:handleAddLoseSkills(player, "ol_ex__paiyi")
  end,
})

return zili
