local xiongwei = fk.CreateSkill {
  name = "xiongwei",
}

Fk:loadTranslationTable{
  ["xiongwei"] = "雄威",
  [":xiongwei"] = "你与魏势力角色拼点后，你获得其拼点牌，若如此做，且其没有“军合”效果，你可以将任意次“军合”效果转移给其。",

  ["#xiongwei-give"] = "雄威：你可以将任意次“军合”效果转移给 %dest",

  ["$xiongwei1"] = "呵呵呵，独夫之心，非百城可易！",
  ["$xiongwei2"] = "设使天下无孤，不知几人称帝，几人称王！",
}

xiongwei:addEffect(fk.PindianFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(xiongwei.name) then
      if data.from == player then
        for to, result in pairs(data.results) do
          if to.kingdom == "wei" then
            if result.toCard and player.room:getCardArea(result.toCard) == Card.Processing then
              return true
            end
          end
        end
      elseif table.contains(data.tos, player) and data.from.kingdom == "wei" then
        if data.fromCard and player.room:getCardArea(data.fromCard) == Card.Processing then
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards, targets = {}, {}
    if data.from == player then
      for to, result in pairs(data.results) do
        if to.kingdom == "wei" then
          if result.toCard and room:getCardArea(result.toCard) == Card.Processing then
            table.insertTableIfNeed(cards, Card:getIdList(result.toCard))
          end
          table.insertIfNeed(targets, to)
        end
      end
    elseif table.contains(data.tos, player) and data.from.kingdom == "wei" then
      if data.fromCard and room:getCardArea(data.fromCard) == Card.Processing then
        table.insertTableIfNeed(cards, Card:getIdList(data.fromCard))
      end
      table.insertIfNeed(targets, data.from)
    end
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, xiongwei.name, nil, true, player)
    end
    if player:getMark("@junhe") == 0 then return end
    targets = table.filter(targets, function(p)
      return p:getMark("@junhe") == 0 and not p.dead
    end)
    if #targets == 0 then return end
    room:sortByAction(targets)
    for _, p in ipairs(targets) do
      local n = room:askToNumber(player, {
        skill_name = xiongwei.name,
        prompt = "#xiongwei-give::"..p.id,
        min = 1,
        max = player:getMark("@junhe"),
        cancelable = true,
      })
      if n ~= nil then
        local junheRecord = player:getMark("junhe_record")
        room:removePlayerMark(player, "@junhe", n)
        if player:getMark("@junhe") == 0 then
          room:setPlayerMark(player, "junhe_record", 0)
        end

        room:addPlayerMark(p, "@junhe", n)
        room:setPlayerMark(p, "junhe_record", junheRecord)
        if player:getMark("@junhe") == 0 then return end
      end
    end
  end,
})

return xiongwei
