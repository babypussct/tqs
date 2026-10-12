local skill = fk.CreateSkill {
  name = "#bone_mirror_skill",
  attached_equip = "bone_mirror",
}

Fk:loadTranslationTable{
  ["#bone_mirror_skill"] = "照骨镜",
  ["#bone_mirror-use"] = "照骨镜：你可以展示一张基本牌或普通锦囊牌，视为使用之",
}

skill:addEffect(fk.EventPhaseEnd, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and player.phase == Player.Play and
      not player:isKongcheng()
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "bone_mirror_viewas",
      prompt = "#bone_mirror-use",
      cancelable = true,
      extra_data = { bypass_times = true },
    })
    if success and dat then
      event:setCostData(self, {cards = dat.cards, extra_data = dat.targets})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:cloneCard(Fk:getCardById(event:getCostData(self).cards[1]).name)
    card.skillName = skill.name
    player:showCards(event:getCostData(self).cards)
    room:useCard{
      from = player,
      tos = event:getCostData(self).extra_data,
      card = card,
    }
  end,
})

return skill
