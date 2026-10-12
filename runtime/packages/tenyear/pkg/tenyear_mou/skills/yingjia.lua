local yingjia = fk.CreateSkill {
  name = "ty__yingjia",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty__yingjia"] = "迎驾",
  [":ty__yingjia"] = "锁定技，你对其他角色使用牌后，本回合你计算与其距离视为1，然后若你与所有其他角色距离均为1，你可以获得"..
  "一名其他角色所有手牌，然后交给其等量的牌（每名角色每回合限一次）。",

  ["#ty__yingjia-choose"] = "迎驾：你可以获得一名角色所有手牌，交给其等量的牌",
  ["#ty__yingjia-give"] = "迎驾：交给 %dest %arg张牌",

  ["$ty__yingjia1"] = "洪奉兖州牧将令，迎陛下于许昌。",
  ["$ty__yingjia2"] = "吾兄不忍天子蒙尘，已扫榻相待。",
}

yingjia:addEffect(fk.CardUseFinished, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yingjia.name) and
      table.find(data.tos, function (p)
        return p ~= player
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(data.tos) do
      if p ~= player and not p.dead then
        room:addTableMarkIfNeed(player, "ty__yingjia-turn", p.id)
      end
    end
    if table.every(room:getOtherPlayers(player, false), function (p)
      return player:distanceTo(p) == 1
    end) then
      local targets = table.filter(room:getOtherPlayers(player, false), function (p)
        return not p:isKongcheng() and not table.contains(player:getTableMark("ty__yingjia_prey-turn"), p.id)
      end)
      if #targets > 0 then
        local to = room:askToChoosePlayers(player, {
          min_num = 1,
          max_num = 1,
          targets = targets,
          skill_name = yingjia.name,
          prompt = "#ty__yingjia-choose",
          cancelable = true,
        })
        if #to > 0 then
          to = to[1]
          room:addTableMarkIfNeed(player, "ty__yingjia_prey-turn", to.id)
          local n = to:getHandcardNum()
          room:moveCardTo(to:getCardIds("h"), Card.PlayerHand, player, fk.ReasonPrey, yingjia.name, nil, false, player)
          if player.dead or to.dead or player:isNude() then return end
          local cards = player:getCardIds("he")
          if #cards > n then
            cards = room:askToCards(player, {
              min_num = n,
              max_num = n,
              include_equip = true,
              skill_name = yingjia.name,
              prompt = "#ty__yingjia-give::"..to.id..":"..n,
              cancelable = false,
            })
          end
          room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonGive, yingjia.name, nil, false, player)
        end
      end
    end
  end,
})

yingjia:addEffect("distance", {
  fixed_func = function(self, from, to)
    if table.contains(from:getTableMark("ty__yingjia-turn"), to.id) then
      return 1
    end
  end,
})

yingjia:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "ty__yingjia_prey-turn", 0)
end)

return yingjia
