local qixian = fk.CreateSkill {
  name = "jiange__qixian",
}

Fk:loadTranslationTable{
  ["jiange__qixian"] = "启弦",
  [":jiange__qixian"] = "当你于出牌阶段获得一张牌后，本回合你使用的下一张【杀】伤害+1。",

  ["@jiange__qixian-turn"] = "启弦",
}

qixian:addEffect(fk.AfterCardsMove, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(qixian.name) and player.phase == Player.Play then
      local n = 0
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Player.Hand then
          n = n + #move.moveInfo
        end
      end
      if n > 0 then
        event:setCostData(self, {choice = n})
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@jiange__qixian-turn", event:getCostData(self).choice)
  end,
})

qixian:addEffect(fk.PreCardUse, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@jiange__qixian-turn") > 0 and
      data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + player:getMark("@jiange__qixian-turn")
    player.room:setPlayerMark(player, "@jiange__qixian-turn", 0)
  end,
})

return qixian
