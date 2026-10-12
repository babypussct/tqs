
local xiubei = fk.CreateSkill {
  name = "xiubei",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["xiubei"] = "修备",
  [":xiubei"] = "锁定技，你参与的拼点中，拼点双方若装备区有牌，须用其装备区里的牌拼点。"..
  "然后若你没赢，你从牌堆中获得与你拼点牌颜色相同的基本牌与装备牌各一张。",

  ["$xiubei1"] = "修兴兼守备，以御待叛贼！",
  ["$xiubei2"] = "众吏怀忠义，白刃忘死生！",
}

xiubei:addEffect(fk.PindianResultConfirmed, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xiubei.name) and
      (data.from == player or data.to == player) and data.winner ~= player
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local color
    if data.from == player then
      if data.fromCard then
        color = data.fromCard:getColorString()
      end
    else
      if data.toCard then
        color = data.toCard:getColorString()
      end
    end
    if color and color ~= "nocolor" then
      local cards = room:getCardsFromPileByRule(".|.|"..color.."|.|.|basic")
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|"..color.."|.|.|equip"))
      if #cards > 0 then
        room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, xiubei.name, nil, false, player)
      end
    end
  end,
})

xiubei:addEffect(fk.BeforeRequestAsk, {
  can_refresh = function (self, event, target, player, data)
    if player:hasSkill(xiubei.name) and data and data.focus_text == "AskForPindian" then
      local pindian_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Pindian, true)
      if pindian_event then
        local pindian = pindian_event.data
        if pindian.from == player and not pindian.fromCard and #pindian.from:getCardIds("e") > 0 then
          return true
        end
        if table.contains(pindian.tos, player) then
          for _ , p in ipairs(pindian.tos) do
            if not (pindian.results[p] and pindian.results[p].toCard) and #p:getCardIds("e") > 0 then
              return true
            end
          end
        end
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    data = data or {}
    local cards = {}
    for pid, v in pairs(data.data) do
      v[4].include_equip = true
      local to = room:getPlayerById(pid)
      if #to:getCardIds("e") > 0 then
        table.insertTable(cards, to:getCardIds("e"))
      else
        table.insertTable(cards, table.filter(to:getCardIds("he"), function (id)
          return Fk:getCardById(id):matchPattern(v[4].pattern)
        end))
      end
    end
    for _, v in pairs(data.data) do
      v[4].pattern = tostring(Exppattern{ id = cards })  --FIXME: 修改一个data会影响所有req，原因未知
      break
    end
  end,
})

return xiubei
