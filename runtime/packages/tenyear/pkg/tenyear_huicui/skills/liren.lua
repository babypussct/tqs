
local liren = fk.CreateSkill {
  name = "liren",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["liren"] = "砺刃",
  [":liren"] = "锁定技，你的攻击范围始终为2。有【杀】造成伤害后，你获得此【杀】；有【杀】被抵消后，你摸一张牌。每回合至多以此法获得三张牌。",

  ["$liren1"] = "横剑在膝，我有一刃解倒悬。",
  ["$liren2"] = "日月煎一剑，天地自纵横！",
}

liren:addEffect(fk.Damage, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(liren.name) and
      data.card and data.card.trueName == "slash" and player.room:getCardArea(data.card) == Card.Processing and
      player:getMark("liren-turn") < 3
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "liren-turn", #Card:getIdList(data.card))
    room:moveCardTo(data.card, Card.PlayerHand, player, fk.ReasonJustMove, liren.name, nil, true, player)
  end,
})

liren:addEffect(fk.CardEffectCancelledOut, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(liren.name) and
      data.card.trueName == "slash" and player:getMark("liren-turn") < 3
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "liren-turn", 1)
    player:drawCards(1, liren.name)
  end,
})

liren:addEffect("atkrange", {
  final_func = function (self, player)
    if player:hasSkill(liren.name) then
      return 2
    end
  end,
})

return liren
