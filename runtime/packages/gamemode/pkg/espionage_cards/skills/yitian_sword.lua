local skill = fk.CreateSkill {
  name = "#yitian_sword_skill",
  attached_equip = "yitian_sword",
}

Fk:loadTranslationTable{
  ["#yitian_sword_skill"] = "倚天剑",
  ["#yitian_sword-invoke"] = "倚天剑：你可以弃置一张手牌，回复1点体力",
}

skill:addEffect(fk.Damage, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      data.card and data.card.trueName == "slash" and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = skill.name,
      cancelable = true,
      prompt = "#yitian_sword-invoke",
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, skill.name, player, player)
    if not player.dead and player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = skill.name,
      }
    end
  end,
})

return skill
