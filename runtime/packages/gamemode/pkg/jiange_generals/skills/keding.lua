local keding = fk.CreateSkill {
  name = "jiange__keding",
}

Fk:loadTranslationTable{
  ["jiange__keding"] = "克定",
  [":jiange__keding"] = "当你使用【杀】或普通锦囊牌指定唯一目标时，你可以弃置任意张手牌，为此牌增加等量的目标。",

  ["#jiange__keding-choose"] = "克定：你可以弃置任意张手牌，为此%arg增加等量的目标",
}

keding:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(keding.name) and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and #data.tos == 1 and
      #data:getExtraTargets() > 0 and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos, cards = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = #data:getExtraTargets(),
      min_num = 1,
      max_num = #data:getExtraTargets(),
      targets = data:getExtraTargets(),
      skill_name = keding.name,
      prompt = "#jiange__keding-choose:::"..data.card:toLogString(),
      cancelable = true,
      will_throw = true,
    })
    if #tos > 0 and #cards > 0 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos, cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(event:getCostData(self).tos) do
      data:addTarget(p)
    end
    room:throwCard(event:getCostData(self).cards, keding.name, player, player)
  end,
})

return keding
