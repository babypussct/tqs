local osZhenliang = fk.CreateSkill {
  name = "os__zhenliang",
  tags = { Skill.Switch },
}

Fk:loadTranslationTable{
  ["os__zhenliang"] = "贞良",
  [":os__zhenliang"] = "转换技，阳：出牌阶段限一次，你可弃置一张牌并选择你攻击范围内的一名其他角色，对其造成1点伤害；" ..
  "阴：你的回合外，当你或你攻击范围内的一名角色受到伤害时，你可弃置一张牌，令此伤害-1。若你以此法弃置的牌与“任”颜色相同，你摸一张牌。",

  [":os__zhenliang_yang"] = "转换技，<font color=\"#E0DB2F\">阳：出牌阶段限一次，你可弃置一张牌并选择你攻击范围内的一名其他角色，对其造成1点伤害；</font>" ..
  "阴：你的回合外，当你或你攻击范围内的一名角色受到伤害时，你可弃置一张牌，令此伤害-1。若你以此法弃置的牌与“任”颜色相同，你摸一张牌。",
  [":os__zhenliang_yin"] = "转换技，阳：出牌阶段限一次，你可弃置一张牌并选择你攻击范围内的一名其他角色，对其造成1点伤害；" ..
  "<font color=\"#E0DB2F\">阴：你的回合外，当你或你攻击范围内的一名角色受到伤害时，你可弃置一张牌，令此伤害-1。</font>若你以此法弃置的牌与“任”颜色相同，你摸一张牌。",

  ["#os__zhenliang-active"] = "贞良:你可弃置一张牌并选择你攻击范围内的一名其他角色，对其造成1点伤害",
  ["#os__zhenliang-discard"] = "贞良：你可弃置一张牌，令 %src 受到的伤害-1",

  ["$os__zhenliang1"] = "贞洁贤良，吾之本心。",
  ["$os__zhenliang2"] = "风霜以别草木之性，危乱而见贞良之节。",
}

-- ActiveSkill effect
osZhenliang:addEffect("active", {
  prompt = "#os__zhenliang-active",
  anim_type = "switch",
  can_use = function(self, player)
    return
      player:usedSkillTimes(osZhenliang.name, Player.HistoryPhase) < 1 and
      player:getSwitchSkillState(osZhenliang.name) == fk.SwitchYang
  end,
  card_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected < 1
  end,
  target_num = 1,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and player:inMyAttackRange(to_select, nil, selected_cards)
  end,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = osZhenliang.name
    if #effect.cards ~= 1 then return end
    local player = effect.from
    local target = effect.tos[1]
    room:throwCard(effect.cards, skillName, player, player)
    room:damage{
      from = player,
      to = target,
      damage = 1,
      skillName = skillName,
    }
    if
      #player:getPile("os__duty") > 0 and
      Fk:getCardById(effect.cards[1]):compareColorWith(Fk:getCardById(player:getPile("os__duty")[1]))
    then
      player:drawCards(1, skillName)
    end
  end,
})

-- TriggerSkill effect
osZhenliang:addEffect(fk.DamageInflicted, {
  anim_type = "switch",
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(osZhenliang.name) and
      player:getSwitchSkillState("os__zhenliang") == fk.SwitchYin and
      (target == player or player:inMyAttackRange(target)) and
      not player:isNude() and
      player.phase == Player.NotActive
  end,
  on_cost = function(self, event, target, player, data)
    local cids = player.room:askToDiscard(
      player,
      {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = osZhenliang.name,
        prompt = "#os__zhenliang-discard:" .. target.id,
        skip = true,
      }
    )
    if #cids > 0 then
      event:setCostData(self, cids)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osZhenliang.name
    local room = player.room
    local cardIds = event:getCostData(self)
    room:throwCard(cardIds, skillName, player, player)
    data:changeDamage(-1)
    if
      #player:getPile("os__duty") > 0 and
      Fk:getCardById(cardIds[1]):compareColorWith(Fk:getCardById(player:getPile("os__duty")[1]))
    then
      player:drawCards(1, skillName)
    end
  end,
})

return osZhenliang
