local pigua = fk.CreateSkill {
  name = "pigua",
}

Fk:loadTranslationTable{
  ["pigua"] = "披挂",
  [":pigua"] = "当你对其他角色造成伤害后，若伤害值大于1，可以获得其至多当前轮数张的手牌，这些牌本回合不计入手牌上限。",

  ["#pigua-invoke"] = "披挂：你可以获得 %dest 至多%arg张手牌",
  ["#pigua-prey"] = "披挂：获得 %dest 至多%arg张手牌",

  ["$pigua1"] = "坚城在握，你刘玄德又奈我何？",
  ["$pigua2"] = "今日披挂上阵，定要斩关羽、诛张飞！",
}

pigua:addEffect(fk.Damage, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(pigua.name) and
      data.damage > 1 and data.to ~= player and not data.to:isKongcheng()
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = pigua.name,
      prompt = "#pigua-invoke::"..data.to.id..":"..room:getBanner("RoundCount"),
    }) then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToChooseCards(player, {
      target = data.to,
      min = 1,
      max = room:getBanner("RoundCount"),
      flag = "h",
      skill_name = pigua.name,
      prompt = "#pigua-prey::"..data.to.id..":"..room:getBanner("RoundCount"),
    })
    room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, pigua.name, nil, false, player, "pigua-inhand-turn")
  end,
})

pigua:addEffect("maxcards", {
  exclude_from = function (self, player, card)
    return card:getMark("pigua-inhand-turn") > 0
  end,
})

return pigua
