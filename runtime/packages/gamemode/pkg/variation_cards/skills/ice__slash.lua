local skill = fk.CreateSkill {
  name = "ice__slash_skill",
}

Fk:loadTranslationTable{
  ["#ice_damage_skill-invoke"] = "你可以防止对 %dest 造成的冰冻伤害，改为依次弃置其两张牌",
  ["ice_damage_skill"] = "冰冻伤害",
}

local slash_skill = Fk.skills["slash_skill"] --[[ @as ActiveSkill ]]

skill:addEffect("cardskill", {
  prompt = function(self, player, selected_cards)
    local card = Fk:cloneCard("ice__slash")
    card:addSubcards(selected_cards)
    local max_num = self:getMaxTargetNum(player, card)
    if max_num > 1 then
      local num = #table.filter(Fk:currentRoom().alive_players, function (p)
        return p ~= player and not player:isProhibited(p, card)
      end)
      max_num = math.min(num, max_num)
    end
    return max_num > 1 and "#ice__slash_skill_multi:::" .. max_num or "#ice__slash_skill"
  end,
  max_phase_use_time = 1,
  target_num = 1,
  can_use = slash_skill.canUse,
  mod_target_filter = slash_skill.modTargetFilter,
  target_filter = slash_skill.targetFilter,
  on_effect = function(self, room, effect)
    room:damage({
      from = effect.from,
      to = effect.to,
      card = effect.card,
      damage = 1,
      damageType = fk.IceDamage,
      skillName = skill.name,
    })
  end,
})

skill:addEffect(fk.DamageCaused, {
  global = true,
  priority = 0,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.damageType == fk.IceDamage and
      not data.chain and not data.to:isNude() and not player.dead
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = "ice_damage_skill",
      prompt = "#ice_damage_skill-invoke::"..data.to.id,
    }) then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data:preventDamage()
    for _ = 1, 2 do
      if data.to:isNude() or data.to.dead or player.dead then break end
      local card = room:askToChooseCard(player, {
        target = data.to,
        flag = "he",
        skill_name = "ice_damage_skill",
      })
      room:throwCard(card, "ice_damage_skill", data.to, player)
    end
  end,
})

return skill
