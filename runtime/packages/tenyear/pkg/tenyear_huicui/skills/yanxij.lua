local yanxij = fk.CreateSkill {
  name = "yanxij",
  dynamic_desc = function (self, player, lang)
    return "yanxij_inner:"..player:getMark(self.name)
  end,
}

Fk:loadTranslationTable{
  ["yanxij"] = "掩袭",
  [":yanxij"] = "每局游戏限零次，其他角色回合结束时，你可以视为对其使用一张【杀】，此【杀】造成的伤害改为失去体力，"..
  "结算后若此技能可使用次数不为0，再次发动直到无使用次数或其阵亡。",

  [":yanxij_inner"] = "（还剩{1}次）其他角色回合结束时，你可以视为对其使用一张【杀】，此【杀】造成的伤害改为失去体力，"..
  "结算后若此技能可使用次数不为0，再次发动直到无使用次数或其阵亡。",

  ["#yanxij-invoke"] = "掩袭：你可以视为对 %dest 使用%arg张失去体力的【杀】！",

  ["$yanxij1"] = "今日先杀王必，明日再斩曹操！",
  ["$yanxij2"] = "我等趁夜掩杀，曹贼必无可逃！",
}

yanxij:addEffect(fk.TurnEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(yanxij.name) and
      not target.dead and player:getMark(yanxij.name) > 0 and
      player:canUseTo(Fk:cloneCard("slash"), target, { bypass_distances = true, bypass_times = true })
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = yanxij.name,
      prompt = "#yanxij-invoke::"..target.id..":"..player:getMark(yanxij.name),
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    while player:getMark(yanxij.name) > 0 and not target.dead and
      player:canUseTo(Fk:cloneCard("slash"), target, { bypass_distances = true, bypass_times = true }) do
      room:removePlayerMark(player, yanxij.name, 1)
      room:useVirtualCard("slash", nil, player, target, yanxij.name, true)
    end
  end,
})

yanxij:addEffect(fk.DamageCaused, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return data.card and table.contains(data.card.skillNames, yanxij.name)
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(data.to, data.damage, yanxij.name)
    data.damage = 0
  end,
})

yanxij:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, yanxij.name, 0)
end)

return yanxij
