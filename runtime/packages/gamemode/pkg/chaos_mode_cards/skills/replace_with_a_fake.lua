local skill = fk.CreateSkill {
  name = "replace_with_a_fake_skill",
}

skill:addEffect("cardskill", {
  prompt = "#replace_with_a_fake_skill",
  mod_target_filter = Util.TrueFunc,
  can_use = Util.CanUseToSelf,
  on_effect = function(self, room, effect)
    local cards = {}
    local moveInfos = {}
    for _, p in ipairs(room:getAlivePlayers()) do
      if #p:getCardIds("e") > 0 then
        table.insert(moveInfos, {
          ids = p:getCardIds("e"),
          from = p,
          toArea = Card.Processing,
          moveReason = fk.ReasonJustMove,
          skillName = skill.name,
        })
        table.insertTable(cards, p:getCardIds("e"))
      end
    end
    if #cards == 0 then return false end
    room:moveCards(table.unpack(moveInfos))
    local dat = {}
    local players = table.simpleClone(room.alive_players)
    for _, cid in ipairs(cards) do
      if room:getCardArea(cid) == Card.Processing then
        table.shuffle(players)
        local target
        local subtype = Fk:getCardById(cid).sub_type
        for _, p in ipairs(players) do
          if #table.filter(dat[p] or {}, function (id)
            return Fk:getCardById(id).sub_type == subtype
          end) < #p:getAvailableEquipSlots(subtype) - #p:getEquipments(subtype) then
            target = p
            break
          end
        end
        if target then
          dat[target] = dat[target] or {}
          table.insertIfNeed(dat[target], cid)
        end
      end
    end
    room:delay(1000)
    if dat ~= {} then
      moveInfos = {}
      for _, p in ipairs(room:getAlivePlayers()) do
        if dat[p] then
          table.insert(moveInfos, {
            ids = dat[p],
            fromArea = Card.Processing,
            to = p,
            toArea = Card.PlayerEquip,
            moveReason = fk.ReasonJustMove,
            skillName = skill.name,
          })
        end
      end
      if #moveInfos > 0 then
        room:moveCards(table.unpack(moveInfos))
      end
    end
    room:cleanProcessingArea(cards)
  end,
})

return skill
