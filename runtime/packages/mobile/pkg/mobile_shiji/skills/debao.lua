local debao = fk.CreateSkill {
  name = "debao",
  derived_piles = "$huaxin_ren",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["debao"] = "德报",
  [":debao"] = "锁定技，当其他角色获得你的牌后，若“仁”数小于你的体力上限，你将牌堆顶一张牌置为“仁”。准备阶段，你获得所有“仁”。",

  ["$huaxin_ren"] = "仁",

  ["$debao1"] = "举手而为之事，何禁诸君盛赞。",
  ["$debao2"] = "仁仕作之不止，德报随之即来。",
}

debao:addEffect(fk.AfterCardsMove, {
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(debao.name) and #player:getPile("$huaxin_ren") < player.maxHp then
      for _, move in ipairs(data) do
        if move.from == player and move.to and move.to ~= player and move.toArea == Card.PlayerHand then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:addToPile("$huaxin_ren", player.room:getNCards(1), false, debao.name)
  end,
})
debao:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(debao.name) and player.phase == Player.Start and #player:getPile("$huaxin_ren") > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player, player:getPile("$huaxin_ren"), false, fk.ReasonJustMove, player, debao.name)
  end,
})

return debao
