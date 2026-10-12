
local mieyi = fk.CreateSkill {
  name = "heg__mieyi",
}

Fk:loadTranslationTable{
  ["heg__mieyi"] = "灭翼",
  [":heg__mieyi"] = "当你受到伤害后，你可以展示所有手牌并将其中所有伤害类牌当一张【远交近攻】使用。",

  ["#heg__mieyi-invoke"] = "灭翼：你可以展示所有手牌，将其中的伤害牌当一张【远交近攻】使用",
  ["#heg__mieyi-use"] = "灭翼：选择一名角色，将其中的伤害牌当【远交近攻】对其使用",
}

mieyi:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(mieyi.name) and not player:isKongcheng()
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = mieyi.name,
      prompt = "#heg__mieyi-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:showCards(player:getCardIds("h"))
    if player.dead then return end
    local cards = table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id).is_damage_card
    end)
    room:askToUseVirtualCard(player, {
      name = "befriend_attacking",
      skill_name = mieyi.name,
      prompt = "#heg__mieyi-use",
      cancelable = false,
      subcards = cards,
    })
  end,
})

return mieyi
