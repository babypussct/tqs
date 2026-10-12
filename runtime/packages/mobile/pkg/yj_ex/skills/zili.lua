local zili = fk.CreateSkill {
  name = "m_ex__zili",
  tags = { Skill.Wake },
  related_skills = { "paiyi" },
}

Fk:loadTranslationTable{
  ["m_ex__zili"] = "自立",
  [":m_ex__zili"] = "觉醒技，准备阶段，若“权”的数量不小于3，你选择一项：1.回复1点体力；2.摸两张牌。然后减1点体力上限，获得〖排异〗。",

  ["$m_ex__zili1"] = "吾功名盖世，岂可复为人下？",
  ["$m_ex__zili2"] = "天赐良机，不取何为？",
}

zili:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zili.name) and
      player.phase == Player.Start and
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
      skill_name = zili.name,
      all_choices = { "draw2", "recover" },
    })
    if choice == "draw2" then
      player:drawCards(2, zili.name)
    else
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = zili.name
      })
    end
    if player.dead then return false end
    room:changeMaxHp(player, -1)
    if player.dead then return false end
    room:handleAddLoseSkills(player, "paiyi")
  end,
})

return zili
