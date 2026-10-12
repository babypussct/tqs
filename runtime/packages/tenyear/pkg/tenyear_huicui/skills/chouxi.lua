local chouxi = fk.CreateSkill {
  name = "chouxic",
  --tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["chouxic"] = "仇隙",
  [":chouxic"] = "当你受到伤害后，你可以视为使用一张牌名字数至多为X的伤害牌。"..
  "当你弃置手牌时，若弃置手牌数大于等于剩余手牌数，你随机获得一张牌名字数至多为X的伤害牌，此牌无次数限制（X为本轮此技能使用的次数）。",

  ["#chouxic-use"] = "仇隙：你可以视为使用一张伤害牌",
  ["@@chouxic-inhand"] = "仇隙",

  ["$chouxic1"] = "",
  ["$chouxic2"] = "",
}

chouxi:addEffect(fk.Damaged, {
  anim_type = "offensive",
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local names = table.filter(Fk:getAllCardNames("bt"), function (name)
      local card = Fk:cloneCard(name)
      return card.is_damage_card and card:getNameLength() <= 1 + player:usedSkillTimes(chouxi.name, Player.HistoryRound)
    end)
    local use = room:askToUseVirtualCard(player, {
      name = names,
      skill_name = chouxi.name,
      prompt = "#chouxic-use",
      cancelable = true,
      extra_data = {
        bypass_times = true,
        extraUse = true,
      },
      skip = true,
    })
    if use then
      event:setCostData(self, { extra_data = use })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:useCard(event:getCostData(self).extra_data)
  end,
})

chouxi:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(chouxi.name) then
      local n = player:getHandcardNum()
      for _, move in ipairs(data) do
        if move.from == player and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Player.Hand then
              n = n - 1
              if n < 1 then
                return true
              end
            end
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    for _, id in ipairs(room.draw_pile) do
      local card = Fk:getCardById(id)
      if card.is_damage_card and card:getNameLength() <= 1 + player:usedSkillTimes(chouxi.name, Player.HistoryRound) then
        table.insert(cards, id)
      end
    end
    if #cards == 0 then
      for _, id in ipairs(room.discard_pile) do
        local card = Fk:getCardById(id)
        if card.is_damage_card and card:getNameLength() <= 1 + player:usedSkillTimes(chouxi.name, Player.HistoryRound) then
          table.insert(cards, id)
        end
      end
    end
    if #cards > 0 then
      room:moveCardTo(room:tableRandomPick(cards), Card.PlayerHand, player, fk.ReasonJustMove, chouxi.name, nil, false, player,
        "@@chouxic-inhand")
    end
  end,
})

chouxi:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player and #Card:getIdList(data.card) == 1 and
      Fk:getCardById(Card:getIdList(data.card)[1], true):getMark("@@chouxic-inhand") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.extraUse = true
  end
})
chouxi:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and card:getMark("@@chouxic-inhand") > 0
  end,
})

return chouxi
