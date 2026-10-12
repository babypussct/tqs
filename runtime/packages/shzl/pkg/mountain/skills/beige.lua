local beige = fk.CreateSkill {
  name = "beige",
}

Fk:loadTranslationTable{
  ["beige"] = "悲歌",
  [":beige"] = "当一名角色受到【杀】造成的伤害后，你可以弃置一张牌，然后令其进行判定，若结果为：<font color='red'>♥</font>，其回复1点体力；"..
  "<font color='red'>♦</font>，其摸两张牌；♣，伤害来源弃置两张牌；♠，伤害来源翻面。",

  ["#beige-invoke"] = "悲歌：%dest 受到伤害，你可以弃置一张牌令其判定，根据花色执行效果",

  ["$beige1"] = "悲歌可以当泣，远望可以当归。",
  ["$beige2"] = "制兹八拍兮拟排忧，何知曲成兮心转愁。",
}

beige:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(beige.name) and
      data.card and data.card.trueName == "slash" and
      not data.to.dead and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = beige.name,
      cancelable = true,
      prompt = "#beige-invoke::"..target.id,
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {tos = {target}, cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, beige.name, player, player)
    if target.dead then return false end
    local judge = {
      who = target,
      reason = beige.name,
      pattern = {
        ["."] = "good",
        ["else"] = "bad"
      },
    }
    for _, suit in ipairs({ "heart", "diamond", "club", "spade" }) do
      judge.pattern[".|.|" .. suit] = suit
    end
    room:judge(judge)
    if not judge.results then return end
    if table.contains(judge.results, "heart") then
      if not target.dead and target:isWounded() then
        room:recover{
          who = target,
          num = 1,
          recoverBy = player,
          skillName = beige.name,
        }
      end
    elseif table.contains(judge.results, "diamond") then
      if not target.dead then
        target:drawCards(2, beige.name)
      end
    elseif table.contains(judge.results, "club") then
      if data.from and not data.from.dead then
        room:askToDiscard(data.from, {
          min_num = 2,
          max_num = 2,
          include_equip = true,
          skill_name = beige.name,
          cancelable = false,
        })
      end
    elseif table.contains(judge.results, "spade") then
      if data.from and not data.from.dead then
        data.from:turnOver()
      end
    end
  end,
})

beige:addAI(Fk.Ltk.AI.newDiscardStrategy {
  choose_cards = function(self, ai)
    if ai.data[2]:startsWith("#beige-invoke") then
      local target = ai.room:getPlayerById(tonumber(string.split(ai.data[2], ":")[3]))
      local data = ai.room.logic:getCurrentEvent().data._data
      local available_cards = ai:getEnabledCards()
      ai:sortCards(available_cards, "keep_value")

      local card = Fk:getCardById(ai.room.draw_pile[1] or 1)
      local benefit = ai:getBenefitOfEvents(function(logic)
        logic:moveCardTo(available_cards[1], Card.DiscardPile, nil, fk.ReasonDiscard)
        logic:judge({
          who = target,
          reason = self.skill_name,
          pattern = ".",
        })
        if card then
          if card.suit == Card.Heart then
            logic:recover{
              who = target,
              num = 1,
              recoverBy = ai.player,
            }
          elseif card.suit == Card.Diamond then
            logic:drawCards(target, 2)
          elseif card.suit == Card.Club then
            if data.from then
              logic:throwCard(table.random(data.from:getCardIds("he"), 2), self.skill_name, data.from, data.from)
            end
          elseif card.suit == Card.Spade then
            if data.from then
              logic:setPlayerProperty(data.from, "faceup", not data.from.faceup)
            end
          end
        end
      end)
      if benefit >= 0 then
        return { available_cards[1] }, benefit
      end
    end
  end,
})

return beige
