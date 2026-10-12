local fengyang = fk.CreateSkill {
  name = "ld__fengyang",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["ld__fengyang"] = "风扬",
  [":ld__fengyang"] = "阵法技，势力与你不同的角色不能弃置或获得与你处于同一<a href='heg_formation_href'>队列</a>角色装备区里的牌。",

  ["$ld__fengyang1"] = "谁也休想染指江东寸土。",
  ["$ld__fengyang2"] = "如此咽喉要地，吾当倾力守之。",
}

local H = require "packages.hegemony.util"

fengyang:addEffect("arraysummon", {
  array_type = "formation",
})

fengyang:addEffect(fk.BeforeCardsMove, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(fengyang.name) then
      for _, move in ipairs(data) do
        if move.from and H.inFormationRelation(player, move.from) and
          move.proposer and not H.compareKingdomWith(move.proposer, player) and
          (move.moveReason == fk.ReasonDiscard or (move.toArea == Card.PlayerHand and move.moveReason ~= fk.ReasonGive)) then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = {}
    for _, move in ipairs(data) do
      if move.from and H.inFormationRelation(player, move.from) and
        move.proposer and not H.compareKingdomWith(move.proposer, player) and
        (move.moveReason == fk.ReasonDiscard or (move.toArea == Card.PlayerHand and move.moveReason ~= fk.ReasonGive)) then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip then
            table.insert(ids, info.cardId)
          end
        end
      end
    end
    room:cancelMove(data, ids)
  end,
})

return fengyang
