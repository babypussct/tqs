local zhengnan = fk.CreateSkill{
  name = "ofl_heg__zhengnan",
  related_skills = { "hs__wusheng", "m_heg__dangxian", "ld__zhiman" },
}

Fk:loadTranslationTable{
  ["ofl_heg__zhengnan"] = "征南",
  [":ofl_heg__zhengnan"] = "当其他角色死亡后，你可以摸三张牌，并获得〖武圣〗〖当先〗〖制蛮〗中一个你没有的技能。",

  ["#ofl_heg__zhengnan-choice"] = "征南：选择获得的技能",

  ["$ofl_heg__zhengnan1"] = "索全凭丞相差遣，万死不辞！",
  ["$ofl_heg__zhengnan2"] = "末将愿承父志，随丞相出征！",
}

zhengnan:addEffect(fk.Deathed, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhengnan.name)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(3, zhengnan.name)
    if player.dead then return end
    local choices = { "hs__wusheng", "m_heg__dangxian", "ld__zhiman" }
    for i = 3, 1, -1 do
      if player:hasSkill(choices[i], true) then
        table.removeOne(choices, choices[i])
      end
    end
    if #choices > 0 then
      local choice = player.room:askToChoice(player, {
        choices = choices,
        skill_name = zhengnan.name,
        prompt = "#ofl_heg__zhengnan-choice",
        detailed = true,
      })
      player.room:handleAddLoseSkills(player, choice)
    end
  end,
})

return zhengnan
