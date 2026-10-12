local duohui = fk.CreateSkill {
  name = "duohui",
}

Fk:loadTranslationTable{
  ["duohui"] = "堕洄",
  [":duohui"] = "其他角色的准备阶段，其可以交给你一张牌，然后你选择一项：<br>" ..
  "1.交给其另一张同花色的牌；<br>" ..
  "2.令其摸一张牌。",

  ["#duohui-give"] = "堕洄：你可交给 %src 一张牌，其须给你另一张同花色牌或令你摸一张牌",
  ["#duohui-give_same"] = "堕洄：请交给 %dest 另一张%arg牌，否则其摸一张牌",

  ["$duohui1"] = "为使须有辩才，正实非良选。",
  ["$duohui2"] = "愿为益州守于内，不欲辩于外。",
}

duohui:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return
      target ~= player and
      target.phase == Player.Start and
      target:isAlive() and
      not target:isNude() and
      player:hasSkill(duohui.name)
  end,
  on_cost = function(self, event, target, player, data)
    local ids = player.room:askToCards(
      target,
      {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = duohui.name,
        prompt = "#duohui-give:" .. player.id,
      }
    )

    if #ids == 1 then
      event:setCostData(self, { cards = ids })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = duohui.name
    local room = player.room

    ---@type integer[]
    local toGive = event:getCostData(self).cards
    room:obtainCard(player, toGive, false, fk.ReasonGive, target, skillName)

    if not (player:isAlive() and target:isAlive()) then
      return false
    end

    local suit = Fk:getCardById(toGive[1]):getSuitString()
    local ids = room:askToCards(
      player,
      {
        min_num = 1,
        max_num = 1,
        pattern = ".|.|" .. suit .. "|.|.|.|^" .. toGive[1],
        include_equip = true,
        skill_name = skillName,
        prompt = "#duohui-give_same::" .. target.id .. ":" .. suit,
      }
    )

    if #ids == 1 then
      room:obtainCard(target, ids, false, fk.ReasonGive, player, skillName)
    else
      target:drawCards(1, skillName)
    end
  end,
})

return duohui
