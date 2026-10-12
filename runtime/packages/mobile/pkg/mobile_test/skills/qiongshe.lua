
local qiongshe = fk.CreateSkill {
  name = "qiongshe",
}

Fk:loadTranslationTable{
  ["qiongshe"] = "穷涉",
  [":qiongshe"] = "若以下值为质数，你可以于对应时机亮出牌堆顶的八张牌，获得其中点数为质数的牌："..
  "手牌数，摸牌阶段开始时；因此获得牌数，出牌阶段；体力值，弃牌阶段结束时。",

  ["#qiongshe"] = "穷涉：你可以亮出牌堆顶的八张牌，获得其中点数为质数的牌",
  ["@qiongshe"] = "穷涉",

  ["$qiongshe1"] = "今吾学已晚，又敢不尽时？",
  ["$qiongshe2"] = "得时便读，得闲便思，终有所获。"
}

---@param n integer
---@param player Player
---@return boolean
local function isPrime(n, player)
  local max = player.mark["prime_max"] or 0
  if max >= n then
    return player.mark["prime_" .. n]
  else
    for i = max + 1, n do
      local is_prime = true
      if i < 2 then
        is_prime = false
      elseif i == 2 then
        is_prime = true
      elseif i % 2 == 0 then
        is_prime = false
      else
        local j = 3
        while j * j <= i do
          if i % j == 0 then
            is_prime = false
            break
          end
          j = j + 2
        end
      end
      if is_prime then
        player.mark["prime_" .. i] = true
      end
    end
    player.mark["prime_max"] = n
    return player.mark["prime_" .. n]
  end
end

qiongshe:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#qiongshe",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return isPrime(player:getMark("@qiongshe"), player)
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local cards = room:getNCards(8)
    room:turnOverCardsFromDrawPile(player, cards, qiongshe.name)
    room:delay(1200)
    local ids = table.filter(cards, function (id)
      return isPrime(Fk:getCardById(id).number, player)
    end)
    if #ids > 0 then
      room:addPlayerMark(player, "@qiongshe", #ids)
      room:moveCardTo(ids, Card.PlayerHand, player, fk.ReasonJustMove, qiongshe.name, nil, true, player)
    end
    room:cleanProcessingArea(cards)
  end,
})

qiongshe:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(qiongshe.name) and player.phase == Player.Draw and
      isPrime(player:getHandcardNum(), player)
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = qiongshe.name,
      prompt = "#qiongshe",
    })
  end,
  on_use = function (self, event, target, player, data)
    Fk.skills[qiongshe.name]:onUse(player.room, {
      from = player,
      tos = {},
    })
  end,
})

qiongshe:addEffect(fk.EventPhaseEnd, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(qiongshe.name) and player.phase == Player.Discard and
      isPrime(player.hp, player)
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = qiongshe.name,
      prompt = "#qiongshe",
    })
  end,
  on_use = function (self, event, target, player, data)
    Fk.skills[qiongshe.name]:onUse(player.room, {
      from = player,
      tos = {},
    })
  end,
})

qiongshe:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@qiongshe", 0)
end)

return qiongshe
