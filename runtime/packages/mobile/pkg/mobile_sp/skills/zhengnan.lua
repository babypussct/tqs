local zhengnan = fk.CreateSkill{
  name = "zhengnan",
  related_skills = { "wusheng", "dangxian", "zhiman" },
}

Fk:loadTranslationTable{
  ["zhengnan"] = "征南",
  [":zhengnan"] = "当其他角色死亡后，你可以摸三张牌，若如此做，你获得下列技能中的任意一个：〖武圣〗，〖当先〗和〖制蛮〗。",

  ["#zhengnan-choice"] = "征南：选择获得的技能",

  ["$zhengnan1"] = "索全凭丞相差遣，万死不辞！",
  ["$zhengnan2"] = "末将愿承父志，随丞相出征！",
}

zhengnan:addEffect(fk.Deathed, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhengnan.name)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(3, zhengnan.name)
    if player.dead then return end
    local choices = {"wusheng", "dangxian", "zhiman"}
    for i = 3, 1, -1 do
      if player:hasSkill(choices[i], true) then
        table.removeOne(choices, choices[i])
      end
    end
    if #choices > 0 then
      local choice = player.room:askToChoice(player, {
        choices = choices,
        skill_name = zhengnan.name,
        prompt = "#zhengnan-choice",
        detailed = true,
      })
      player.room:handleAddLoseSkills(player, choice)
    end
  end,
})

return zhengnan
