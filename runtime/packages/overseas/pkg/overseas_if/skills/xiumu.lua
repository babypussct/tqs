local xiumu = fk.CreateSkill {
  name = "os__xiumu",
}

Fk:loadTranslationTable{
  ["os__xiumu"] = "修睦",
  [":os__xiumu"] = "当你受到伤害后，你可以令一名其他角色选择任意张点数之和不小于13的手牌与你的全部手牌交换（不足则全交换）。",

  ["#os__xiumu-choose"] = "修睦：你可以令一名角色与你交换手牌",
  ["#os__xiumu-ask"] = "修睦：请选择点数之和不小于13的手牌，交换 %src 的全部手牌",

  ["$os__xiumu1"] = "你我共辅皇兄大业，大魏必享国万年！",
  ["$os__xiumu2"] = "手足之情，岂能为权欲所动？",
}

xiumu:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function (self, event, target, player, data)
    if target == player and player:hasSkill(xiumu.name) then
      if not player:isKongcheng() then
        return #player.room:getOtherPlayers(player, false) > 0
      else
        return table.find(player.room:getOtherPlayers(player, false), function (p)
          return not p:isKongcheng()
        end)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = room:getOtherPlayers(player, false)
    if player:isKongcheng() then
      targets = table.filter(targets, function (p)
        return not p:isKongcheng()
      end)
    end
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = xiumu.name,
      prompt = "#os__xiumu-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local n = 0
    for _, id in ipairs(to:getCardIds("h")) do
      n = n + Fk:getCardById(id).number
    end
    if n < 13 then
      room:swapAllCards(player, {player, to}, xiumu.name)
    else
      local success, dat = room:askToUseActiveSkill(to, {
        skill_name = "os__xiumu_active",
        prompt = "#os__xiumu-ask:"..player.id,
        cancelable = false,
      })
      if not (success and dat) then
        dat = {}
        dat.cards = to:getCardIds("h")
      end
      room:swapCards(player, {
        {player, player:getCardIds("h")},
        {to, dat.cards},
      }, xiumu.name)
    end
  end,
})

return xiumu
