local osDidao = fk.CreateSkill {
  name = "os__didao"
}

Fk:loadTranslationTable{
  ["os__didao"] = "地道",
  [":os__didao"] = "当一名角色的判定牌生效前，你可打出一张牌替换之，若与原判定牌颜色相同，你摸一张牌。",

  ["#os__didao-ask"] = "地道：你可打出一张牌替换 %src 的判定，若与原判定牌颜色相同，你摸一张牌",
}

osDidao:addEffect(fk.AskForRetrial, {
  anim_type = "control",
  can_trigger = function(self, event, target, player)
    return player:hasSkill(osDidao.name) and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local ids = table.filter(player:getCardIds("he"), function (id)
      return not player:prohibitResponse(Fk:getCardById(id))
    end)
    local cards = player.room:askToCards(
      player,
      {
        min_num = 1,
        max_num = 1,
        skill_name = osDidao.name,
        pattern = tostring(Exppattern{ id = ids }),
        prompt = "#ex__guicai-ask::" .. target.id,
      }
    )
    if #cards > 0 then
      event:setCostData(self, cards[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osDidao.name
    local invoke = false
    local cardChosen = Fk:getCardById(event:getCostData(self))
    if cardChosen:compareColorWith(data.card) then
      invoke = true
    end

    player.room:changeJudge{
      card = cardChosen,
      player = player,
      data = data,
      skillName = skillName,
      response = true,
    }
    if invoke and player:isAlive() then
      player:drawCards(1, skillName)
    end
  end,
})

return osDidao
