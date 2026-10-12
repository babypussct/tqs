
local shengxi = fk.CreateSkill{
  name = "shengxi",
}

Fk:loadTranslationTable{
  ["shengxi"] = "生息",
  [":shengxi"] = "弃牌阶段开始时，若你于此回合内未造成过伤害，你可以摸两张牌。",

  ["$shengxi1"] = "国之生计，在民生息。",
  ["$shengxi2"] = "安民止战，兴汉室！",
}

shengxi:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(shengxi.name) and player.phase == Player.Discard and
      #player.room.logic:getActualDamageEvents(1, function(e) return e.data.from == player end) == 0
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, shengxi.name)
  end,
})

shengxi:addAI(Fk.Ltk.AI.newInvokeStrategy{
  think = function(self, ai)
    return ai:getBenefitOfEvents(function(logic)
      logic:drawCards(ai.player, 2, self.skill_name)
    end) >= 0
  end,
})

return shengxi
