local fuchen = fk.CreateSkill{
  name = "os__fuchen",
  tags = { Skill.Compulsory },
  related_skills = { "mou__wushuang", "mou__biyue" }
}

Fk:loadTranslationTable{
  ["os__fuchen"] = "浮沉",
  [":os__fuchen"] = "锁定技，回合开始时，若你的手牌均为黑色/红色，你获得〖无双〗/〖闭月〗。",
}

fuchen:addEffect(fk.TurnStart, {
  can_trigger = function (self, event, target, player, data)
    if not (player:hasSkill(fuchen.name) and player == target and not player:isKongcheng()) then return end
    local cards = player:getCardIds(Player.Hand)
    local color = Fk:getCardById(cards[1]).color
    if color == Card.NoColor then return end
    if table.every(cards, function (c)
      return color == Fk:getCardById(c).color
    end) then
      local skill = color == Card.Black and "mou__wushuang" or "mou__biyue"
      if player:hasSkill(skill, true) then return end
      event:setCostData(self, {skill = skill})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local skill = event:getCostData(self).skill
    player.room:handleAddLoseSkills(player, skill)
  end,
})

return fuchen
