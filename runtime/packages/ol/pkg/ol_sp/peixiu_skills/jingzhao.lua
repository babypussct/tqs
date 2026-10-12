local jingzhao = fk.CreateSkill {
  name = "peixiu_jingzhao",
}

Fk:loadTranslationTable {
  ["peixiu_jingzhao"] = "京兆",
  [":peixiu_jingzhao"] = "若有角色本回合对你使用过：【杀】/伤害锦囊牌，伤害锦囊牌/【杀】对你无效。",
}

jingzhao:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(jingzhao.name) then
      if data.card.trueName == "slash" then
        return #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
          return e.data.card.type == Card.TypeTrick and e.data.card.is_damage_card
        end, Player.HistoryTurn) > 0
      elseif data.card.type == Card.TypeTrick and data.card.is_damage_card then
        return #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
          return e.data.card.trueName == "slash"
        end, Player.HistoryTurn) > 0
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.nullified = true
  end,
})

return jingzhao
