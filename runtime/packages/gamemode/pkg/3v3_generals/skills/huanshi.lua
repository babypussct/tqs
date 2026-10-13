local huanshi = fk.CreateSkill {
  name = "v33__huanshi",
}

Fk:loadTranslationTable{
  ["v33__huanshi"] = "缓释",
  [":v33__huanshi"] = "当己方角色的判定牌生效前，你可以打出一张牌代替之。",

  ["#v33__huanshi-invoke"] = "缓释：是否打出一张牌修改 %dest 的判定牌？",
}

huanshi:addEffect(fk.AskForRetrial, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(huanshi.name) and target:isFriend(player) and
      not (player:isNude() and #player:getHandlyIds() == 0)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local ids = table.filter(table.connect(player:getHandlyIds(), player:getCardIds("e")), function (id)
      return not player:prohibitResponse(Fk:getCardById(id))
    end)
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      skill_name = huanshi.name,
      pattern = tostring(Exppattern{ id = ids}),
      prompt = "#v33__huanshi-invoke::"..target.id,
      cancelable = true,
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:changeJudge{
      card = Fk:getCardById(event:getCostData(self).cards[1]),
      player = player,
      data = data,
      skillName = huanshi.name,
      response = true,
    }
  end,
})

return huanshi
