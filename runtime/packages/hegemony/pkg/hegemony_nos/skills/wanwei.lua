
local wanwei = fk.CreateSkill{
  name = "nos_heg__wanwei",
}

Fk:loadTranslationTable{
  ["nos_heg__wanwei"] = "挽危",
  [":nos_heg__wanwei"] = "当你的牌被其他角色获得或弃置时，你可以改为自己选择失去的牌。",

  ["#nos_heg__wanwei-ask"] = "挽危：请选择%arg张即将被其他角色获得或弃置的牌",

  ["$nos_heg__wanwei1"] = "梁、沛之间，非子廉无有今日。",
  ["$nos_heg__wanwei2"] = "正使祸至，共死何苦！",
}

wanwei:addEffect(fk.BeforeCardsMove, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(wanwei.name) then
      local _data = {}
      for index, move in ipairs(data) do
        local num = 0
        if (move.moveReason == fk.ReasonPrey or move.moveReason == fk.ReasonDiscard) and move.from == player and move.proposer ~= player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip or info.fromArea == Card.PlayerHand then
              num = num + 1
            end
          end
        end
        if num ~= 0 then
          table.insert(_data, {index, num})
        end
      end
      if #_data == 0 then return end
      event:setCostData(self, { _data = _data })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if player.dead then return end
    local room = player.room
    local _data = event:getCostData(self)._data
    for _, tab in ipairs(_data) do
      local index, num = tab[1], tab[2]
      local ids = room:askToChooseCards(player, {
        target = player,
        min = num,
        max = num,
        flag = "he",
        skill_name = wanwei.name,
        prompt = "#nos_heg__wanwei-ask:::"..num,
      })
      if #ids == num then
        local moveInfo = {}
        for _, id in ipairs(ids) do
          local from = room:getCardArea(id)
          local info = {}
          info.cardId = id
          info.beforeCard = Fk:getCardById(id)
          info.fromArea = from
          table.insertIfNeed(moveInfo, info)
        end
        if #moveInfo == num then
          data[index].moveInfo = moveInfo
        end
      end
    end
  end,
})

return wanwei
