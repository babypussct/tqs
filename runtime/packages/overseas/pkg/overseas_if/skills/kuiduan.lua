local kuiduan = fk.CreateSkill {
  name = "os__kuiduan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__kuiduan"] = "溃端",
  [":os__kuiduan"] = "锁定技，当你使用【杀】指定唯一目标后，你与其各将随机两张手牌标记为“溃端”牌（视为【杀】）。你的“溃端”牌不记入手牌上限。"..
    "结束阶段，你视为对一名其他角色使用一张【决斗】，此牌造成伤害后，伤害来源摸X张牌（X为你手牌中【杀】和“溃端”牌的数量且至多为5）。",

  ["@@os__kuiduan_rout-inhand"] = "溃端",
  ["#os__kuiduan-duel"] = "溃端：视为对一名其他角色使用【决斗】",

  ["$os__kuiduan1"] = "蜀军大败，吾等岂能失此战机！",
  ["$os__kuiduan2"] = "求胜心切，竟轻中敌计。",
}

kuiduan:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(kuiduan.name) and target == player and data.card.trueName == "slash" and
      data:isOnlyTarget(data.to)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    for _, p in ipairs{player, data.to} do
      local cards = table.filter(p:getCardIds("h"), function (id)
        return Fk:getCardById(id):getMark("@@os__kuiduan_rout-inhand") == 0
      end)
      cards = room:tableRandomPick(cards, math.min(2, #cards)) ---@type integer[]
      if #cards > 0 then
        for _, id in ipairs(cards) do
          room:setCardMark(Fk:getCardById(id), "@@os__kuiduan_rout-inhand", 1)
        end
      end
    end
  end,
})

kuiduan:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    if target == player and player:hasSkill(kuiduan.name) and player.phase == Player.Finish then
      local card = Fk:cloneCard("duel")
      card.skillName = kuiduan.name
      return table.find(player.room.alive_players, function (p)
        return player:canUseTo(card, p)
      end)
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local card = Fk:cloneCard("duel")
    card.skillName = kuiduan.name
    local tos = table.filter(player.room.alive_players, function (p)
      return player:canUseTo(card, p)
    end)
    if #tos == 0 then return end
    local to = #tos > 1 and room:askToChoosePlayers(player, {
      targets = tos,
      min_num = 1,
      max_num = 1,
      prompt = "#os__kuiduan-duel",
      skill_name = kuiduan.name,
      cancelable = false,
    })[1] or tos[1]
    room:useCard{
      from = player,
      tos = { to },
      card = card,
      extraUse = true,
      extra_data = { os__kuiduan = true }
    }
  end,
})

kuiduan:addEffect(fk.Damage, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    if target ~= player or data.card == nil or data.chain then return false end
    local c_event = player.room.logic:getCurrentEvent():findParent(GameEvent.CardEffect, false)
    if c_event == nil then return false end
    local use_data = c_event.data
    return (use_data.extra_data or Util.DummyTable).os__kuiduan and data.card == use_data.card
  end,
  on_use = function (self, event, target, player, data)
    local n = 0
    local current = player.room.logic:getCurrentEvent():findParent(GameEvent.CardEffect, false).data.from
    for _, id in ipairs(current:getCardIds("h")) do
      if Fk:getCardById(id).trueName == "slash" then
        n = n + 1
        if n == 5 then break end
      end
    end
    player:drawCards(n, kuiduan.name)
  end
})

kuiduan:addEffect("filter", {
  mute = true,
  card_filter = function(self, card)
    return card:getMark("@@os__kuiduan_rout-inhand") > 0
  end,
  view_as = function(self, player, card)
    return Fk:cloneCard("slash", card.suit, card.number)
  end,
})

kuiduan:addEffect("maxcards", {
  exclude_from = function (self, player, card)
    return card:getMark("@@os__kuiduan_rout-inhand") > 0 and player:hasSkill(kuiduan.name)
  end
})

return kuiduan
