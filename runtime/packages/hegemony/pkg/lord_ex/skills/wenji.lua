
local wenji = fk.CreateSkill {
  name = "ld__wenji",
}

Fk:loadTranslationTable {
  ["ld__wenji"] = "问计",
  [":ld__wenji"] = "出牌阶段开始时，你可以令一名其他角色展示并交给你一张牌，"..
  "你于此回合内使用此牌无距离与次数限制且不能被响应，且结算后你交给其另一张牌。",

  ["#ld__wenji-choose"] = "问计：令一名其他角色交给你一张牌",
  ["#ld__wenji-give"] = "问计：请交给 %dest 一张牌",

  ["$ld__wenji1"] = "言出子口，入于吾耳，可以言未？",
  ["$ld__wenji2"] = "还望先生救我！",
}

wenji:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wenji.name) and player.phase == Player.Play and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return not p:isNude()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return not p:isNude()
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#ld__wenji-choose",
      skill_name = wenji.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { to = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).to[1]
    local card = room:askToCards(to, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      prompt = "#ld__wenji-give::" .. player.id,
      skill_name = wenji.name,
      cancelable = false,
    })
    room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonGive, wenji.name, nil, true, to, { "ld__wenji-turn", { player, to } })
  end,
})

wenji:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and table.find(Card:getIdList(card), function (id)
      return Fk:getCardById(id):getTableMark("ld__wenji-turn")[1] == player
    end)
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and table.find(Card:getIdList(card), function (id)
      return Fk:getCardById(id):getTableMark("ld__wenji-turn")[1] == player
    end)
  end,
})

wenji:addEffect(fk.CardUsing, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and
      table.find(Card:getIdList(data.card), function (id)
        return Fk:getCardById(id):getTableMark("ld__wenji-turn")[1] == player
      end)
  end,
  on_use = function(self, event, target, player, data)
    data:setDisresponsive()
  end,
})

wenji:addEffect(fk.CardUseFinished, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wenji.name) and
      not player:isNude() and
      table.find(Card:getIdList(data.card), function (id)
        local mark = Fk:getCardById(id):getTableMark("ld__wenji-turn")
        return mark and mark[1] == player and not mark[2].dead
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local info = {}
    for _, id in ipairs(Card:getIdList(data.card)) do
      local mark = Fk:getCardById(id):getTableMark("ld__wenji-turn")
      if mark[1] == player then
        table.insert(info, { mark[2], id })
      end
    end
    for _, dat in ipairs(info) do
      if player:isNude() then return end
      if not dat[1].dead then
        local cards = player:getCardIds("he")
        table.removeOne(cards, dat[2])
        if #cards > 0 then
          local card = room:askToCards(player, {
            min_num = 1,
            max_num = 1,
            include_equip = true,
            skill_name = wenji.name,
            pattern = tostring(Exppattern{ id = cards }),
            prompt = "#ld__wenji-give::" .. dat[1].id,
            cancelable = false,
          })
          room:moveCardTo(card, Card.PlayerHand, dat[1], fk.ReasonGive, wenji.name, nil, false, player)
        end
      end
    end
  end,
})

return wenji
