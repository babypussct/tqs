local yuxi = fk.CreateSkill {
  name = "yuxi",
}

Fk:loadTranslationTable{
  ["yuxi"] = "驭袭",
  [":yuxi"] = "当你造成或受到伤害时，你可以摸一张牌，以此法获得的牌无次数限制。",

  ["@@yuxi-inhand"] = "驭袭",

  ["$yuxi1"] = "任他千军来，我只一枪去！",
  ["$yuxi2"] = "长枪雪恨，斩尽胡马！"
}

local spec = {
  anim_type = "drawcard",
  on_use = function (self, event, target, player, data)
    player:drawCards(1, yuxi.name, nil, "@@yuxi-inhand")
  end
}

yuxi:addEffect(fk.DetermineDamageCaused, spec)
yuxi:addEffect(fk.DetermineDamageInflicted, spec)

yuxi:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player and #Card:getIdList(data.card) == 1 and
      Fk:getCardById(Card:getIdList(data.card)[1], true):getMark("@@yuxi-inhand") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.extraUse = true
  end
})
yuxi:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and card:getMark("@@yuxi-inhand") > 0
  end,
})

local AI = Fk.Ltk.AI
yuxi:addAI(AI.reuse("biyue", AI.InvokeStrategy))

return yuxi
