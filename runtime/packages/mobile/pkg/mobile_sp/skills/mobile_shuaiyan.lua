local mobileShuaiyan = fk.CreateSkill {
  name = "mobile__shuaiyan",
}

Fk:loadTranslationTable{
  ["mobile__shuaiyan"] = "率言",
  [":mobile__shuaiyan"] = "弃牌阶段开始时，若你的手牌数大于1，你可以展示所有手牌，令一名其他角色交给你一张牌。",

  ["#mobile__shuaiyan-choose"] = "率言：你可展示所有手牌，令一名其他角色交给你一张牌",
  ["#mobile__shuaiyan-give"] = "率言：交给 %dest 一张牌",

  ["$mobile__shuaiyan1"] = "天无二日，士无二主。",
  ["$mobile__shuaiyan2"] = "吾言意欲为吴，非但为蜀也。",
}

mobileShuaiyan:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
  return
    target == player and
    player:hasSkill(mobileShuaiyan.name) and
    player.phase == Player.Discard and
    player:getHandcardNum() > 1 and
    table.find(player.room:getOtherPlayers(player, false), function(p) return not p:isNude() end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p) return not p:isNude() end)
    if #targets > 0 then
      local tos = room:askToChoosePlayers(
        player,
        {
          targets = targets,
          min_num = 1,
          max_num = 1,
          prompt = "#mobile__shuaiyan-choose",
          skill_name = mobileShuaiyan.name,
        }
      )
      if #tos > 0 then
        event:setCostData(self, { tos = tos })
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = mobileShuaiyan.name
    local room = player.room
    player:showCards(player:getCardIds("h"))
    local to = event:getCostData(self).tos[1]
    if player:isAlive() and not to:isNude() then
      local cards = room:askToCards(
        to,
        {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = skillName,
          cancelable = false,
          prompt = "#mobile__shuaiyan-give::" .. player.id,
        }
      )
      room:moveCardTo(cards, Player.Hand, player, fk.ReasonGive, skillName, nil, false, to)
    end
  end,
})

return mobileShuaiyan
