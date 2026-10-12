
local longnu = fk.CreateSkill {
  name = "ty__longnu",
  tags = { Skill.Compulsory, Skill.Switch },
}

Fk:loadTranslationTable{
  ["ty__longnu"] = "龙怒",
  [":ty__longnu"] = "转换技，锁定技，出牌阶段开始时，"..
  "阳：你失去1点体力并摸等同于你已损失体力值张牌，然后本回合你的红色手牌均视为火【杀】且无距离限制；"..
  "阴：你减1点体力上限并摸等同于你体力值张牌，然后本回合你的锦囊牌均视为雷【杀】且无次数限制。",

  ["$ty__longnu1"] = "神龙降天怒，雷火镇仇雠！",
  ["$ty__longnu2"] = "手足之殇，不共戴天！",
}

longnu:addEffect(fk.EventPhaseStart, {
  anim_type = "switch",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(longnu.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getSwitchSkillState(longnu.name, true) == fk.SwitchYang then
      room:loseHp(player, 1, longnu.name)
      if player.dead then return end
      if player:isWounded() then
        player:drawCards(player:getLostHp(), longnu.name)
        if player.dead then return end
      end
      room:setPlayerMark(player, "ty__longnu-turn", "yang")
    else
      room:changeMaxHp(player, -1)
      if player.dead then return end
      if player.hp > 0 then
        player:drawCards(player.hp, longnu.name)
        if player.dead then return end
      end
      room:setPlayerMark(player, "ty__longnu-turn", "yin")
    end
  end,
})
longnu:addEffect("filter", {
  anim_type = "offensive",
  card_filter = function(self, to_select, player)
    if player:hasSkill(longnu.name) and player.phase == Player.Play and
    table.contains(player:getCardIds("h"), to_select.id) then
      if player:getMark("ty__longnu-turn") == "yang" then
        return to_select.color == Card.Red
      elseif player:getMark("ty__longnu-turn") == "yin" then
        return to_select.type == Card.TypeTrick
      end
    end
  end,
  view_as = function(self, player, to_select)
    local card
    if player:getMark("ty__longnu-turn") == "yang" then
      card = Fk:cloneCard("fire__slash", to_select.suit, to_select.number)
    elseif player:getMark("ty__longnu-turn") == "yin" then
      card = Fk:cloneCard("thunder__slash", to_select.suit, to_select.number)
    end
    card.skillName = longnu.name
    return card
  end,
})

longnu:addEffect("targetmod", {
  bypass_distances =  function(self, player, skill, card, to)
    return player:getMark("ty__longnu-turn") == "yang" and card and card.name == "fire__slash"
  end,
  bypass_times = function(self, player, skill, scope, card, to)
    return player:getMark("ty__longnu-turn") == "yin" and card and card.name == "thunder__slash"
  end,
})

return longnu
