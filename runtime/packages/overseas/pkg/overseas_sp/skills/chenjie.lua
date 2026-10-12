
local chenjie = fk.CreateSkill{
  name = "chenjie",
}

Fk:loadTranslationTable{
  ["chenjie"] = "臣节",
  [":chenjie"] = "当一名角色的判定牌生效前，你可以用一张与判定牌相同花色的牌代替之，然后你摸两张牌。",

  ["#chenjie-invoke"] = "臣节：你可以打出一张%arg牌修改 %dest 的“%arg2”判定并摸两张牌",

  ["$chenjie1"] = "臣心怀二心，不可事君也。",
  ["$chenjie2"] = "竭力致身，以尽臣节。",
}

chenjie:addEffect(fk.AskForRetrial, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(chenjie.name) and
      (not player:isNude() or #player:getHandlyIds() > 0) and
      data.card
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local allIds = table.connect(player:getHandlyIds(), player:getCardIds("e"))
    local ids = table.filter(allIds, function (id)
      return not player:prohibitResponse(Fk:getCardById(id)) and Fk:getCardById(id).suit == data.card.suit
    end)
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      skill_name = chenjie.name,
      pattern = tostring( Exppattern{ id = ids } ),
      prompt = "#chenjie-invoke::"..target.id..":"..data.card:getSuitString(true)..":"..data.reason,
      include_equip = true,
      cancelable = true,
    })
    if #cards > 0 then
      event:setCostData(self, { cards = cards })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:changeJudge{
      card = Fk:getCardById(event:getCostData(self).cards[1]),
      player = player,
      data = data,
      skillName = chenjie.name,
    }
    if not player.dead then
      player:drawCards(2, chenjie.name)
    end
  end,
})

return chenjie
