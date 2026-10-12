local buqu = fk.CreateSkill{
  name = "hs__buqu",
  derived_piles = "hs__buqu_scar",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["hs__buqu"] = "不屈",
  [":hs__buqu"] = "锁定技，当你处于濒死状态时，你将牌堆顶的一张牌置于你的武将牌上，称为“创”，"..
  "若此牌的点数与已有的“创”点数：均不同，你将体力回复至1点；存在相同，你移去此牌。",

  ["hs__buqu_scar"] = "创",

  ["$hs__buqu1"] = "战如熊虎，不惜躯命！",
  ["$hs__buqu2"] = "哼，这点小伤算什么！",
}

buqu:addEffect(fk.AskForPeaches, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(buqu.name) and player.dying
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local scar_id =room:getNCards(1)[1]
    local scar = Fk:getCardById(scar_id)
    player:addToPile("hs__buqu_scar", scar_id, true, buqu.name)
    if player.dead or not table.contains(player:getPile("hs__buqu_scar"), scar_id) then return false end
    local success = true
    for _, id in pairs(player:getPile("hs__buqu_scar")) do
      if id ~= scar_id then
        local card = Fk:getCardById(id)
        if card.number == scar.number then
          success = false
          break
        end
      end
    end
    if success then
      room:recover({
        who = player,
        num = 1 - player.hp,
        recoverBy = player,
        skillName = buqu.name
      })
    else
      room:moveCardTo(scar, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, buqu.name, "hs__buqu_scar", true, player)
    end
  end,
})

return buqu
