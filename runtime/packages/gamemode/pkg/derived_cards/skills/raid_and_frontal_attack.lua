local skill = fk.CreateSkill {
  name = "raid_and_frontal_attack_skill",
}

Fk:loadTranslationTable{
  ["raid_and_frontal_attack_skill"] = "奇正相生",
  ["#raid_and_frontal_attack_skill"] = "指定目标后选择“奇兵”或“正兵”，根据目标是否打出对应的牌执行效果",
  ["raid_and_frontal_attack_raid"] = "奇兵",
  ["raid_and_frontal_attack_frontal"] = "正兵",
  ["#raid_and_frontal_attack-response"] = "正兵：未出闪，%src 获得你牌；<br>奇兵：未出杀，你受到伤害",
  ["#raid_and_frontal_attack-choose"] = "正兵：%dest 不出闪，你获得其牌；<br>奇兵：其不出杀，其受到伤害",
}

skill:addEffect("cardskill", {
  prompt = "#raid_and_frontal_attack_skill",
  target_num = 1,
  mod_target_filter = function(self, player, to_select, selected)
    return to_select ~= player
  end,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, effect)
    local from = effect.from
    local to = effect.to
    local respond = room:askToResponse(effect.to, {
      skill_name = skill.name,
      pattern = "slash,jink",
      prompt = "#raid_and_frontal_attack-response:" .. from.id,
      cancelable = true,
      event_data = effect,
    })
    if respond then
      room:responseCard(respond)
    end
    local choice = (effect.extra_data or {}).raid_and_frontal_attackChosen or "raid_and_frontal_attack_raid"
    if not (respond and not respond.nullified and
      respond.card.trueName == (choice == "raid_and_frontal_attack_frontal" and "jink" or "slash")) then
      if choice == "raid_and_frontal_attack_raid" then
        room:damage({
          from = from,
          to = to,
          card = effect.card,
          damage = 1,
          skillName = skill.name,
        })
      else
        if not to:isNude() and not from.dead then
          local cardId = room:askToChooseCard(from, {
            target = to,
            flag = "he",
            skill_name = skill.name,
          })
          room:obtainCard(from, cardId, nil, fk.ReasonPrey, from, skill.name)
        end
      end
    end
  end,
})
skill:addEffect(fk.TargetSpecified, {
  global = true,
  priority = 0, -- game rule
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card.name == "raid_and_frontal_attack"
  end,
  on_trigger = function(self, event, target, player, data)
    local choice = player.room:askToChoice(player, {
      choices = { "raid_and_frontal_attack_frontal", "raid_and_frontal_attack_raid" }, -- 正兵，奇兵
      skill_name = skill.name,
      prompt = "#raid_and_frontal_attack-choose::" .. data.to.id,
    })
    data.extra_data = data.extra_data or {}
    data.extra_data.raid_and_frontal_attackChosen = choice
  end,
})

return skill
