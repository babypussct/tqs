local skill = fk.CreateSkill {
  name = "#xingtian_axe_skill",
  attached_equip = "xingtian_axe",
}

Fk:loadTranslationTable{
  ["#xingtian_axe_skill"] = "刑天破军斧",

  ["#xingtian_axe_skill-invoke"] = "刑天破军斧：你可弃置两张牌，令 %dest 本回合不能使用或打出手牌且防具无效",
  ["@@xingtian_axe_skill_prohibited-turn"] = "被刑天破军",
}

skill:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      data:isOnlyTarget(data.to) and
      player.phase == Player.Play and
      player:hasSkill(skill.name)
  end,
  on_cost = function(self, event, target, player, data)
    local cards = {}
    for _, id in ipairs(player:getCardIds("he")) do
      if not player:prohibitDiscard(id) and
        not (table.contains(player:getEquipments(Card.SubtypeWeapon), id)
         and (player:getVirtualEquip(id) or Fk:getCardById(id)).name == "xingtian_axe") then
        table.insert(cards, id)
      end
    end

    cards = player.room:askToDiscard(
      player,
      {
        min_num = 2,
        max_num = 2,
        include_equip = true,
        skill_name = skill.name,
        cancelable = true,
        pattern = tostring(Exppattern{ id = cards }),
        prompt = "#xingtian_axe_skill-invoke::" .. data.to.id,
        skip = true,
      }
    )
    if #cards > 0 then
      event:setCostData(self, { cards = cards })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, skill.name, player, player)

    if data.to:isAlive() then
      room:setPlayerMark(data.to, "@@xingtian_axe_skill_prohibited-turn", 1)
    end
  end,
})

skill:addEffect("invalidity", {
  invalidity_func = function(self, from, sk)
    return
      from:getMark("@@xingtian_axe_skill_prohibited-turn") > 0 and
      sk:getSkeleton().attached_equip and
      Fk:cloneCard(sk:getSkeleton().attached_equip).sub_type == Card.SubtypeArmor
  end,
})

skill:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return player:getMark("@@xingtian_axe_skill_prohibited-turn") > 0
  end,
  prohibit_response = function(self, player, card)
    return player:getMark("@@xingtian_axe_skill_prohibited-turn") > 0
  end,
})

return skill
