local yuanqing = fk.CreateSkill {
  name = "yuanqing",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["yuanqing"] = "渊清",
  [":yuanqing"] = "锁定技，出牌阶段结束时，你随机将弃牌堆中你本回合因使用而置入弃牌堆的牌每种类别各一张置入<a href='RenPile_href'>“仁”区</a>。",

  ["$yuanqing1"] = "怀瑾瑜，握兰桂，而心若芷萱。",
  ["$yuanqing2"] = "嘉言懿行，如渊之清，如玉之洁。",
}

local U = require "packages.utility.utility"

yuanqing:addEffect(fk.EventPhaseEnd, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(yuanqing.name) and player.phase == Player.Play then
      return #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.from == player and move.moveReason == fk.ReasonUse then
            for _, info in ipairs(move.moveInfo) do
              if table.contains(player.room.discard_pile, info.cardId) then
                return true
              end
            end
          end
        end
      end, Player.HistoryTurn) > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.from == player and move.moveReason == fk.ReasonUse then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(player.room.discard_pile, info.cardId) then
              table.insertIfNeed(ids, info.cardId)
            end
          end
        end
      end
    end, Player.HistoryTurn)
    local cards = {}
    for _, type in ipairs({Card.TypeBasic, Card.TypeTrick, Card.TypeEquip}) do
      table.insert(cards, room:tableRandomPick(table.filter(ids, function(id)
        return Fk:getCardById(id).type == type
      end)))
    end
    room:shuffleTable(cards)
    U.AddToRenPile(player, cards, yuanqing.name)
  end,
})

return yuanqing
