
local cuxi = fk.CreateSkill {
  name = "cuxi",
}

Fk:loadTranslationTable {
  ["cuxi"] = "猝袭",
  [":cuxi"] = "其他角色回合开始时，你可以弃置一张牌，然后令其选择一项：1.跳过摸牌阶段并令你摸两张牌；2.其受到你造成的1点伤害。",

  ["#cuxi-invoke"] = "猝袭：你可以弃置一张牌，令 %dest 选择一项",
  ["cuxi_skip"] = "跳过摸牌阶段并令%src摸两张牌",
  ["cuxi_damage"] = "%src对你造成1点伤害",

  ["$cuxi1"] = "",
  ["$cuxi2"] = "",
}

cuxi:addEffect(fk.TurnStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(cuxi.name) and
      not target.dead and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = cuxi.name,
      prompt = "#cuxi-invoke::"..target.id,
      cancelable = true,
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, { tos = { target }, cards = card })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, cuxi.name, player, player)
    if target.dead then return end
    local choices = { "cuxi_skip:" .. player.id, "cuxi_damage:" .. player.id }
    if not player:canSkip(Player.Draw) then
      table.remove(choices, 1)
    end
    local choice = room:askToChoice(target, {
      skill_name = cuxi.name,
      choices = choices,
    })
    if choice:startsWith("cuxi_skip") then
      target:skip(Player.Draw)
      if not player.dead then
        player:drawCards(2, cuxi.name)
      end
    else
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = cuxi.name,
      }
    end
  end,
})

cuxi:addAI(Fk.Ltk.AI.newDiscardStrategy {
  choose_cards = function(self, ai)
    local available_cards = ai:getEnabledCards()
    ai:sortCards(available_cards, "keep_value")
    local benefit = ai:getBenefitOfEvents(function(logic)
      logic:moveCardTo(available_cards[1], Card.DiscardPile, nil, fk.ReasonDiscard)
      logic:damage({
        from = ai.player,
        to = ai.room:getPlayerById(tonumber(string.split(ai.data[2], ":")[2])),
        damage = 1,
        skillName = ai.data[1],
      })
    end)
    if benefit >= 0 then
      return { available_cards[1] }, benefit
    end
  end,
})

return cuxi
