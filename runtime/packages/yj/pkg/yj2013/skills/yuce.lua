local yuce = fk.CreateSkill {
  name = "yuce",
}

Fk:loadTranslationTable{
  ["yuce"] = "御策",
  [":yuce"] = "当你受到伤害后，你可以展示一张手牌，令伤害来源弃置一张类别不同的手牌，否则你回复1点体力。",

  ["#yuce-invoke"] = "御策：你可以展示一张手牌，伤害来源需弃置一张类别不同的手牌，否则你回复1点体力",
  ["#yuce-discard"] = "御策：你需弃置一张非%arg手牌，否则 %src 回复1点体力",

  ["$yuce1"] = "御敌之策，成竹于胸。",
  ["$yuce2"] = "以缓制急，不战屈兵。",
}

yuce:addEffect(fk.Damaged, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yuce.name) and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = yuce.name,
      cancelable = true,
      prompt = "#yuce-invoke",
    })
    if #card > 0 then
      event:setCostData(self, { cards = card })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = event:getCostData(self).cards or {}
    local type = Fk:getCardById(card[1]):getTypeString()
    player:showCards(card)
    if player.dead or not data.from then return end
    local types = { "basic", "trick", "equip" }
    table.removeOne(types, type)
    if data.from.dead or
      #room:askToDiscard(data.from, {
        skill_name = yuce.name,
        include_equip = false,
        min_num = 1,
        max_num = 1,
        pattern = ".|.|.|hand|.|"..table.concat(types, ","),
        prompt = "#yuce-discard:"..player.id.."::"..type,
        cancelable = true,
      }) == 0 then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = yuce.name,
      }
    end
  end,
})

yuce:addAI(Fk.Ltk.AI.newCardsStrategy {
  choose_cards = function(self, ai)
    local data = ai.room.logic:getCurrentEvent().data._data
    if data.from then
      local cards = ai:getEnabledCards()
      if #cards > 0 then
        local ret, benefit = cards[1], 0
        --先找每种类别自己的手牌
        local ret1, ret2, ret3
        for _, id in ipairs(ai.player:getCardIds("h")) do
          if Fk:getCardById(id).type == Card.TypeBasic then
            ret1 = id
          elseif Fk:getCardById(id).type == Card.TypeTrick then
            ret2 = id
          elseif Fk:getCardById(id).type == Card.TypeEquip then
            ret3 = id
          end
        end
        if ai.player:isWounded() then
          --优先尝试回血
          local types = {}
          for _, id in ipairs(data.from:getCardIds("h")) do
            if not data.from:prohibitDiscard(id) then
              table.insertIfNeed(types, Fk:getCardById(id).type)
              if #types == 3 then
                break
              end
            end
          end
          if #types == 0 then
            benefit = ai:getBenefitOfEvents(function(logic)
              logic:recover{
                who = ai.player,
                num = 1,
                recoverBy = ai.player,
              }
            end)
            ret = ret1 or ret3 or ret2
            return { ret }, benefit
          elseif #types == 1 then
            for _, id in ipairs({ ret1, ret2, ret3 }) do
              if id and Fk:getCardById(id).type == types[1] then
                benefit = ai:getBenefitOfEvents(function(logic)
                  logic:recover{
                    who = ai.player,
                    num = 1,
                    recoverBy = ai.player,
                  }
                end)
                return { id }, benefit
              end
            end
          end
        end
        --尝试弃牌
        for _, id in ipairs({ ret1, ret2, ret3 }) do
          if id then
            local handcards = table.filter(data.from:getCardIds("h"), function (c)
              return Fk:getCardById(id).type ~= Fk:getCardById(c).type and not data.from:prohibitDiscard(id)
            end)
            ai:sortCards(handcards, "use_value")
            if #handcards > 0 then
              local tmp = ai:getBenefitOfEvents(function(logic)
                logic:throwCard(handcards[1], self.skill_name, data.from)
              end)
              if tmp >= benefit then
                ret, benefit = id, tmp
              end
            end
          end
        end
        return { ret }, benefit
      end
    end
  end,
})

return yuce
