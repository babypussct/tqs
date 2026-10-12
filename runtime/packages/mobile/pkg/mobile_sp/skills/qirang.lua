local qirang = fk.CreateSkill {
  name = "qirang",
}

Fk:loadTranslationTable{
  ["qirang"] = "祈禳",
  [":qirang"] = "当装备牌置入你的装备区后，你可以从牌堆随机获得一张锦囊牌，你使用此锦囊牌时无距离限制并摸一张牌。",

  ["@@qirang-inhand"] = "祈禳",

  ["$qirang1"] = "集母亲之智，效父亲之法，祈以七星。",
  ["$qirang2"] = "仙甲既来，岂无仙术乎。",
}

qirang:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(qirang.name) then
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Player.Equip then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getCardsFromPileByRule(".|.|.|.|.|trick")
    if #cards > 0 then
      room:moveCardTo(room:tableRandomPick(cards), Card.PlayerHand, player, fk.ReasonJustMove, qirang.name, nil, false, player,
        "@@qirang-inhand")
    end
  end,
})

qirang:addEffect(fk.CardUsing, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and data.card.type == Card.TypeTrick and
      #data:getMark("@@qirang-inhand") > 0 and not player.dead
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, qirang.name)
  end,
})

qirang:addEffect("targetmod", {
  bypass_distances = function (self, player, skill, card, to)
    return card and card.type == Card.TypeTrick and card:getMark("@@qirang-inhand") > 0
  end,
})

return qirang
