local shenpin = fk.CreateSkill{
  name = "shenpin",
}

Fk:loadTranslationTable{
  ["shenpin"] = "神品",
  [":shenpin"] = "当一名角色的判定牌生效前，你可以打出一张与判定牌颜色不同的牌代替之。",

  ["#shenpin-invoke"] = "神品：你可以打出%arg牌代替 %dest 的“%arg2”判定",

  ["$shenpin1"] = "考其遗法，肃若神明。",
  ["$shenpin2"] = "气韵生动，出于天成。",
}

shenpin:addEffect(fk.AskForRetrial, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shenpin.name) and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local allIds = table.connect(player:getHandlyIds(), player:getCardIds("e"))
    local ids = table.filter(allIds, function (id)
      return not player:prohibitResponse(Fk:getCardById(id)) and Fk:getCardById(id).color ~= data.card.color
    end)
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      skill_name = shenpin.name,
      pattern = tostring( Exppattern{ id = ids } ),
      include_equip = true,
      prompt = "#shenpin-invoke::"..target.id..":"..(data.card.color == Card.Black and "red" or "black")..":"..data.reason,
      expand_pile = player:getHandlyIds(false),
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
      skillName = shenpin.name,
      response = true,
    }
  end,
})

return shenpin
