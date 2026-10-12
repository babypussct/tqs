local qianhuan = fk.CreateSkill{
  name = "qianhuan",
  derived_piles = "yuji_sorcery",
}
local H = require "packages.hegemony.util"
qianhuan:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(qianhuan.name) and not target.dead and H.compareKingdomWith(target, player)
      and not player:isNude() and #player:getPile("yuji_sorcery") < 4
  end,
  on_cost = function(self, event, target, player, data)
    local card = {}
    local room = player.room
    local suits = {}
    for _, id in ipairs(player:getPile("yuji_sorcery")) do
      table.insert(suits, Fk:getCardById(id):getSuitString())
    end
    card = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = qianhuan.name,
      pattern = ".|.|^(" .. table.concat(suits, ",") .. ")",
      prompt = "#qianhuan-dmg",
      cancelable = true,
      expand_pile = "yuji_sorcery",
    })
    if #card > 0 then
      event:setCostData(self, {cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player:addToPile("yuji_sorcery", event:getCostData(self).cards, true, qianhuan.name)
  end,
})
qianhuan:addEffect(fk.TargetConfirming, {
  anim_type = "defensive",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(qianhuan.name) and H.compareKingdomWith(target, player) and #player:getPile("yuji_sorcery") > 0 and
      (data.card.type == Card.TypeBasic or data.card.type == Card.TypeTrick) and data:isOnlyTarget(target)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local card = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = qianhuan.name,
      pattern = ".|.|.|yuji_sorcery",
      prompt = "#qianhuan-def::" .. target.id .. ":" .. data.card:toLogString(),
      cancelable = true,
      expand_pile = "yuji_sorcery",
    })
    if #card > 0 then
      event:setCostData(self, {cards = card})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:moveCardTo(event:getCostData(self).cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, qianhuan.name, nil, true, player)
    data:cancelTarget(target)
  end
})
qianhuan:addEffect(fk.BeforeCardsMove, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(qianhuan.name) then return false end
    for _, move in ipairs(data) do
      if move.to and move.toArea == Card.PlayerJudge then
        local friend = move.to
        return H.compareKingdomWith(friend, player) and #move.moveInfo > 0 and #player:getPile("yuji_sorcery") > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local card = {}
    local room = player.room
    local delayed_trick = nil
    local friend = nil
    local id, c
    for _, move in ipairs(data) do
      if move.to and move.toArea == Card.PlayerJudge and H.compareKingdomWith(move.to, player) then
        for _, info in ipairs(move.moveInfo) do
          id = info.cardId
          c = Fk:getCardById(id)
          if move.virtualEquip and move.virtualEquip:getEffectiveId() == id then
            c = move.virtualEquip
          end
          if c and c.sub_type == Card.SubtypeDelayedTrick then
            delayed_trick = c
            friend = move.to
            break
          end
        end
      end
    end
    if friend == nil or delayed_trick == nil then return end
    if delayed_trick then
      card = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = qianhuan.name,
        pattern = ".|.|.|yuji_sorcery",
        prompt = "#qianhuan-def::" .. friend.id .. ":" .. delayed_trick:toLogString(),
        cancelable = true,
        expand_pile = "yuji_sorcery",
      })
    end
    if #card > 0 then
      event:setCostData(self, { cards = card, cid = delayed_trick:getEffectiveId() })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:moveCardTo(event:getCostData(self).cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, qianhuan.name, "yuji_sorcery")
    local cid = event:getCostData(self).cid
    local mirror_moves = {}
    player.room:cancelMove(data, nil, function (move, info)
      if info.cardId == cid then
        local mirror_move = move:copy()
        mirror_move.to = nil
        mirror_move.toArea = Card.DiscardPile
        mirror_move.moveInfo = {info}
        mirror_move.moveReason = fk.ReasonJustMove
        mirror_move.skillName = self.skeleton.name
        table.insert(mirror_moves, mirror_move)
        return true
      end
      return false
    end)
    table.insertTable(data, mirror_moves)
  end,
})

Fk:loadTranslationTable{
  ["qianhuan"] = "千幻",
  [":qianhuan"] = "①当与你势力相同的角色受到伤害后，你可将一张与你武将牌上花色均不同的牌置于你的武将牌上（称为“幻”）。②当与你势力相同的角色成为基本牌或锦囊牌的唯一目标时，你可将一张“幻”置入弃牌堆，取消此目标。",

  ["#qianhuan-dmg"] = "千幻：你可一张与“幻”花色均不同的牌置于你的武将牌上（称为“幻”）",
  ["#qianhuan-def"] = "千幻：你可一张“幻”置入弃牌堆，取消%arg的目标 %dest",
  ["yuji_sorcery"] = "幻",

  ["$qianhuan1"] = "幻化于阴阳，藏匿于乾坤。",
  ["$qianhuan2"] = "幻变迷踪，虽飞鸟亦难觅踪迹。",
}

return qianhuan
