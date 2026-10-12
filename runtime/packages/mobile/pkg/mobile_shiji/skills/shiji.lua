local shiji = fk.CreateSkill {
  name = "shiji",
}

Fk:loadTranslationTable{
  ["shiji"] = "势击",
  [":shiji"] = "当你对其他角色造成属性伤害时，若你的手牌数不为全场唯一最多，你可以观看其手牌并弃置其中所有的红色牌，然后你摸等量的牌。",

  ["#shiji-invoke"] = "势击：你可以观看 %dest 的手牌并弃置其中所有红色牌，然后摸等量牌",

  ["$shiji1"] = "敌军依草结营，正犯兵家大忌！",
  ["$shiji2"] = "兵法所云火攻之计，正合此时之势！",
}

shiji:addEffect(fk.DetermineDamageCaused, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shiji.name) and data.to ~= player and
      data.damageType ~= fk.NormalDamage and not data.to:isKongcheng() and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return p:getHandcardNum() >= player:getHandcardNum()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = shiji.name,
      prompt = "#shiji-invoke::"..data.to.id,
    }) then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:viewCards(player, { cards = data.to:getCardIds("h"), skill_name = shiji.name, prompt = "$ViewCardsFrom:"..data.to.id })
    local ids = table.filter(data.to:getCardIds("h"), function (id)
      return Fk:getCardById(id).color == Card.Red
    end)
    if #ids > 0 then
      room:throwCard(ids, shiji.name, data.to, player)
      if not player.dead then
        player:drawCards(#ids, shiji.name)
      end
    end
  end,
})

return shiji
