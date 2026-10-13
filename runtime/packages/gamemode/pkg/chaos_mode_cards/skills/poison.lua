local skill = fk.CreateSkill {
  name = "poison_skill",
}

skill:addEffect("cardskill", {
  prompt = "#poison_skill",
  mod_target_filter = function (self, player, to_select, selected, card, extra_data)
    return to_select.hp > 0
  end,
  can_use = function(self, player, card, extra_data)
    return Util.CanUseToSelf(self, player, card, extra_data) and player.hp > 0
  end,
  on_effect = function(self, room, effect)
    if effect.to.dead then return end
    room:loseHp(effect.to, 1, "poison", effect.from)
  end,
})

skill:addEffect(fk.AfterCardsMove, {
  global = true,
  priority = 0.001,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player.dead then
      for _, move in ipairs(data) do
        if move.from == player and move.skillName ~= "scrape_poison_skill" and move.moveReason ~= fk.ReasonUse then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand and info.beforeCard.name == "poison" and
              (move.moveVisible or
              table.contains({ Card.PlayerEquip, Card.Processing, Card.DiscardPile, Card.Void }, move.toArea)) then
              return true
            end
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local n = 0
    for _, move in ipairs(data) do
        if move.from == player and move.skillName ~= "scrape_poison_skill" and move.moveReason ~= fk.ReasonUse then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand and info.beforeCard.name == "poison" and
              (move.moveVisible or
              table.contains({ Card.PlayerEquip, Card.Processing, Card.DiscardPile, Card.Void }, move.toArea)) then
              n = n + 1
            end
          end
        end
    end
    for _ = 1, n, 1 do
      if not player.dead then
        player.room:loseHp(player, 1, "poison")
      end
    end
  end,
})

skill:addAI(Fk.Ltk.AI.newCardSkillStrategy {
  keep_value = 2.0,
  use_value = -5,
  use_priority = 3.0,

  on_effect = function (self, logic, effect)
    logic:loseHp(effect.to, 1, "poison", effect.from)
  end
})

skill:addTest(function(room, me)
  local poison = room:printCard("poison")
  -- 服务端on_effect测试：能正常摸牌
  FkTest.runInRoom(function()
    room:useCard{
      from = me,
      tos = { me },
      card = poison,
    }
  end)
  lu.assertEquals(#me.hp, 3)
end)

return skill
