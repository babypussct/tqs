local hengwei = fk.CreateSkill {
  name = "hengwei",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["hengwei"] = "横威",
  [":hengwei"] = "锁定技，当你对其他角色造成伤害时，其需展示并交给你一张手牌，否则此伤害+1；你的回合内，" ..
  "其他角色不能使用与其于本回合内展示过的牌颜色相同的牌。",

  ["#hengwei-give"] = "横威：请展示并交给 %src 一张手牌，否则此伤害+1",
  ["@hengwei_record-turn"] = "横威",

  ["$hengwei1"] = "曹操小儿，尔等何虑？待其下寨，吾自擒之。",
  ["$hengwei2"] = "十八路诸侯尚惧我三分，况尔等小卒？",
}

hengwei:addEffect(fk.DamageCaused, {
  can_trigger = function(self, event, target, player, data)
    return target == player and data.to ~= player and player:hasSkill(hengwei.name)
  end,
  on_use = function(self, event, target, player, data)
    if data.to:isAlive() and not data.to:isKongcheng() then
      ---@type string
      local skillName = hengwei.name
      local room = player.room

      local ids = room:askToCards(
        data.to,
        {
          min_num = 1,
          max_num = 1,
          skill_name = skillName,
          prompt = "#hengwei-give:" .. player.id,
        }
      )

      if #ids == 1 then
        data.to:showCards(ids)

        if player:isAlive() then
          room:obtainCard(player, ids, true, fk.ReasonGive, data.to, skillName)
        end

        return false
      end
    end

    data:changeDamage(1)
  end,
})

hengwei:addEffect(fk.CardShown, {
  can_refresh = function(self, event, target, player, data)
    if not (target == player and player:isAlive()) then
      return false
    end

    local current = player.room:getCurrent()
    return current and current ~= player and current:hasSkill(hengwei.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local record = player:getTableMark("@hengwei_record-turn")
    local recordChanged = false
    table.forEach(data.cardIds, function(id)
      local color = Fk:getCardById(id):getColorString()
      if not table.contains({ "nocolor", "unknown" }, color) then
        local success = table.insertIfNeed(record, color)
        recordChanged = recordChanged or success
      end
    end)

    if recordChanged then
      player.room:setPlayerMark(player, "@hengwei_record-turn", record)
    end
  end,
})

hengwei:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    local current = Fk:currentRoom():getCurrent()
    if
      current and
      current ~= player and
      current:hasSkill(hengwei.name) and
      table.contains(player:getTableMark("@hengwei_record-turn"), card:getColorString())
    then
      local subcards = card:isVirtual() and card.subcards or { card.id }
      return #subcards > 0 and
        table.every(subcards, function(id)
          return table.contains(player:getCardIds("h"), id)
        end)
    end
  end,
})

return hengwei
