local zhendu = fk.CreateSkill {
  name = "zhendud",
}

Fk:loadTranslationTable{
  ["zhendud"] = "酖毒",
  [":zhendud"] = "出牌阶段结束时，你可以展示至多5张基本或普通锦囊牌，然后你的下个回合开始时视为依次使用这些牌（无距离限制）。"..
    "你使用这些牌期间有角色回复体力或受到伤害后，你摸一张牌（因此摸到的牌不计本回合手牌上限）。",

  ["#zhendud-ask"] = "酖毒：展示至多5张基本牌或普通锦囊牌，下个回合开始时视为使用这些牌",
  ["@$zhendud"] = "酖毒",
  ["@@zhendud-inhand-turn"] = "酖毒",

  ["$zhendud1"] = "杜鹃泣血成鸩，孤母泪如是。",
  ["$zhendud2"] = "恶贼，杀我儿之时，可曾想过今日！",
}

zhendu:addEffect(fk.EventPhaseEnd, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:hasSkill(zhendu.name) and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = 5,
      skill_name = zhendu.name,
      pattern = ".|.|.|hand|.|basic,normal_trick",
      prompt = "#zhendud-ask",
      cancelable = true,
    })
    if #cards > 0 then
      event:setCostData(self, { cards = cards })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards
    local mark = player:getTableMark("@$zhendud")
    table.insertTableIfNeed(mark, cards)
    room:setPlayerMark(player, "@$zhendud", mark)

    player:showCards(cards)
  end,
})

zhendu:addEffect(fk.TurnStart, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and #player:getTableMark("@$zhendud") > 0
  end,
  on_use = function(self, event, target, player, data)
    local skillName = zhendu.name
    local room = player.room
    local card
    local ids = player:getTableMark("@$zhendud")
    room:setPlayerMark(player, "@$zhendud", 0)
    while true do
      local to_use = table.filter(ids, function(id)
        card = Fk:getCardById(id)
        return (card.type == Card.TypeBasic or card:isCommonTrick()) and not card.is_passive and
          player:canUse(card, { bypass_distances = true, bypass_times = true })
      end)
      if #to_use == 0 then break end
      local use = room:askToUseRealCard(player, {
        pattern = to_use,
        skill_name = skillName,
        extra_data = {
          bypass_distances = true,
          bypass_times = true,
          expand_pile = to_use,
        },
        skip = true
      })
      if use == nil then break end
      table.removeOne(ids, use.card.id)
      use.card = Fk:cloneCard(use.card.name, use.card.suit, 0)
      --实测使用【酒】无次数限制，但计入次数
      if use.card.trueName == "analeptic" then
        use.extraUse = false
      end
      room:useCard(use)
      if player.dead then break end
    end
  end,
})

local spec = {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    local e = player.room.logic:getCurrentEvent()
    while true do
      e = e:findParent(GameEvent.SkillEffect)
      if e then
        if e.data.skill.name == "#zhendud_2_trig" and e.data.who == player then
          return true
        end
      else
        break
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, zhendu.name, nil, "@@zhendud-inhand-turn")
  end,
}

zhendu:addEffect(fk.Damaged, spec)
zhendu:addEffect(fk.HpRecover, spec)

zhendu:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return card:getMark("@@zhendud-inhand-turn") > 0
  end,
})

zhendu:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@$zhendud", 0)
end)

return zhendu
