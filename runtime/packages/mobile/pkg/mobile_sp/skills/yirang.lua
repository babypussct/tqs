local yirang = fk.CreateSkill{
  name = "yirang",
}

Fk:loadTranslationTable{
  ["yirang"] = "揖让",
  [":yirang"] = "出牌阶段开始时，你可以将所有非基本牌（至少一张）交给一名体力上限大于你的其他角色，然后你将体力上限增至与该角色相同并"..
  "回复X点体力（X为你以此法交给其的牌中包含的类别数）。",

  ["#yirang-choose"] = "揖让：将所有非基本牌交给一名角色，将体力上限增至与其相同并回复体力",

  ["$yirang1"] = "明公切勿推辞！",
  ["$yirang2"] = "万望明公可怜汉家城池为重！",
}

yirang:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yirang.name) and player.phase == Player.Play and
      not player:isNude() and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return p.maxHp > player.maxHp
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if not table.find(player:getCardIds("he"), function (id)
      return Fk:getCardById(id).type ~= Card.TypeBasic
    end) then
      room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = yirang.name,
        pattern = "false",
        prompt = "#yirang-choose",
        cancelable = true,
      })
      return
    end
    local targets = table.filter(player.room:getOtherPlayers(player, false), function (p)
      return p.maxHp > player.maxHp
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = yirang.name,
      prompt = "#yirang-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local cards = table.filter(player:getCardIds("he"), function (id)
      return Fk:getCardById(id).type ~= Card.TypeBasic
    end)
    local types = {}
    for _, id in ipairs(cards) do
      table.insertIfNeed(types, Fk:getCardById(id).type)
    end
    room:obtainCard(to, cards, false, fk.ReasonGive, player, yirang.name)
    if player.dead then return end
    if to.maxHp > player.maxHp then
      room:changeMaxHp(player, to.maxHp - player.maxHp)
    end
    if not player.dead and player:isWounded() then
      room:recover {
        num = #types,
        who = player,
        recoverBy = player,
        skillName = yirang.name,
      }
    end
  end,
})

return yirang
