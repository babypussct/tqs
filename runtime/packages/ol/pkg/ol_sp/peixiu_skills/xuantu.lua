local xuantu = fk.CreateSkill {
  name = "peixiu_xuantu",
  max_turn_use_time = 1,
}

Fk:loadTranslationTable {
  ["peixiu_xuantu"] = "玄菟",
  [":peixiu_xuantu"] = "有角色进入濒死状态时，你获得使其进入此濒死状态的牌（每回合限一次）。",
}

xuantu:addEffect(fk.EnterDying, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xuantu.name) and
      player:usedSkillTimes(xuantu.name, Player.HistoryTurn) == 0 and
      table.find(Card:getIdList(data.damage.card), function(cid)
        return player.room:getCardArea(cid) == Card.Processing
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.filter(Card:getIdList(data.damage.card), function(cid)
      return room:getCardArea(cid) == Card.Processing
    end)
    if #cards > 0 then
      room:obtainCard(player, cards, nil, fk.ReasonPrey, player, xuantu.name)
    end
  end,
})

return xuantu
