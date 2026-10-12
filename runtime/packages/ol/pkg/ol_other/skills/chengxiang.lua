local chengxiang = fk.CreateSkill{
  name = "ol__chengxiang",
}

Fk:loadTranslationTable{
  ["ol__chengxiang"] = "称象",
  [":ol__chengxiang"] = "当你受到1点伤害后，你可以亮出牌堆顶四张牌，获得其中任意张数量点数之和不大于13的牌，将其余的牌置入弃牌堆。"..
  "若获得的牌点数之和恰好为13，你下次发动〖称象〗时多亮出一张牌。",

  ["$ol__chengxiang1"] = "大象，大象，你过来啊。",
  ["$ol__chengxiang2"] = "那我问你，象重几何？",
}

chengxiang:addEffect(fk.Damaged, {
  anim_type = "masochism",
  trigger_times = function(self, event, target, player, data)
    return data.damage
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local num = 4
    if player:getMark(chengxiang.name) > 0 then
      num = 5
      room:setPlayerMark(player, chengxiang.name, 0)
    end
    local cards = table.simpleClone(room:getNCards(num))
    if player:hasSkill("ol__duanti") then
      player:broadcastSkillInvoke("ol__duanti")
      room:notifySkillInvoked(player, "ol__duanti", "special")
      cards = {}
      if table.every(room.alive_players, function (p)
        return player.hp <= p.hp
      end) and #player:getTableMark("ol__duanti-round") < 2 then
        local names = table.filter({ "peach", "analeptic" }, function (name)
          return not table.contains(player:getTableMark("ol__duanti-round"), name)
        end)
        cards = room:getCardsFromPileByRule(table.concat(names, ","))
        if #cards > 0 then
          room:addTableMark(player, "ol__duanti-round", Fk:getCardById(cards[1]).trueName)
        end
      end
      if table.every(room.alive_players, function (p)
        return player.hp >= p.hp
      end) then
        local ids = table.filter(room.draw_pile, function (id)
          return Fk:getCardById(id).is_damage_card or Fk:getCardById(id).sub_type == Card.SubtypeWeapon
        end)
        if #ids > 0 then
          table.insert(cards, room:tableRandomPick(ids))
        end
      end
      for _, id in ipairs(room:getNCards(num + #cards)) do
        if #cards >= num then break end
        if not table.contains(cards, id) then
          table.insert(cards, id)
        end
      end
    end
    room:moveCardTo(cards, Card.Processing, nil, fk.ReasonJustMove, chengxiang.name, nil, true, player)
    local get = room:askToArrangeCards(player, {
      skill_name = chengxiang.name,
      card_map = {cards},
      prompt = "#chengxiang-choose",
      free_arrange = false,
      box_size = 0,
      max_limit = {num, num},
      min_limit = {0, 1},
      poxi_type = "chengxiang",
      default_choice = {{}, {cards[1]}},
    })[2]
    local n = 0
    for _, id in ipairs(get) do
      n = n + Fk:getCardById(id).number
    end
    if n == 13 then
      room:setPlayerMark(player, chengxiang.name, 1)
    end
    room:moveCardTo(get, Player.Hand, player, fk.ReasonJustMove, chengxiang.name, nil, true, player)
    room:cleanProcessingArea(cards, chengxiang.name)
  end
})

chengxiang:addAI(Fk.Ltk.AI.newInvokeStrategy{
  think = Util.TrueFunc,
})

return chengxiang
