local xingwu = fk.CreateSkill {
  name = "ol__xingwu",
  derived_piles = "ol__dance",
}

Fk:loadTranslationTable{
  ["ol__xingwu"] = "星舞",
  [":ol__xingwu"] = "弃牌阶段开始时，你可以将一张牌置于你的武将牌上，称为“星舞”，然后你可移去三张“星舞”或翻面并弃置两张手牌，" ..
  "选择一名其他角色，弃置其装备区里的所有牌，若其为男性/女性角色，你对其造成2/1点伤害。",

  ["ol__dance"] = "星舞",
  ["#ol__xingwu-put"] = "星舞：你可将一张牌置于你的武将牌上（称为“星舞”）",
  ["ol__xingwu_remove"] = "星舞：移去三张“星舞”",
  ["ol__xingwu_discard"] = "星舞：翻面并弃置两张手牌",
  ["#ol__xingwu-remove"] = "星舞：请移去三张“星舞”并选择一名其他角色，弃置其装备区里的所有牌，对其造成2/1点伤害",
  ["#ol__xingwu-discard"] = "星舞：请弃置两张手牌并选择一名其他角色，你翻面，弃置其装备区里的所有牌，对其造成2/1点伤害",

  ["$ol__xingwu1"] = "姐妹蝶双飞。",
  ["$ol__xingwu2"] = "星光闪烁，曼妙相随。",
}

xingwu:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    return
      target == player and
      player:hasSkill(xingwu.name) and
      player.phase == Player.Discard and
      not player:isNude()
  end,
  on_cost = function(self, event, target, player)
    local cids = player.room:askToCards(
      player,
      {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = xingwu.name,
        prompt = "#ol__xingwu-put",
      }
    )
    if #cids > 0 then
      event:setCostData(self, cids[1])
      return true
    end
  end,
  on_use = function(self, event, target, player)
    ---@type string
    local skillName = xingwu.name
    local room = player.room
    player:addToPile("ol__dance", event:getCostData(self), true, skillName, player)

    local canDiscard = table.filter(player:getCardIds("h"), function(id) return not player:prohibitDiscard(id) end)
    local choices = {}
    if #player:getPile("ol__dance") > 2 then
      table.insert(choices, "ol__xingwu_remove")
    end
    if #canDiscard > 1 then
      table.insert(choices, "ol__xingwu_discard")
    end

    table.insert(choices, "Cancel")
    local choice = room:askToChoice(
      player,
      {
        choices = choices,
        skill_name = skillName,
        all_choices = { "ol__xingwu_remove", "ol__xingwu_discard", "Cancel" }
      }
    )

    if choice == "Cancel" then
      return false
    end

    local to
    if choice == "ol__xingwu_remove" then
      local plist, cids = room:askToChooseCardsAndPlayers(
        player,
        {
          min_num = 1,
          max_num = 1,
          min_card_num = 3,
          max_card_num = 3,
          targets = room:getOtherPlayers(player, false),
          pattern = ".|.|.|ol__dance",
          skill_name = skillName,
          prompt = "#ol__xingwu-remove",
          extra_data = { expand_pile = "ol__dance" },
          cancelable = false,
        }
      )

      if #plist > 0 and #cids > 0 then
        to = plist[1]
        room:moveCardTo(cids, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, skillName, "os__dance", true, player)
      end
    else
      local plist, cids = room:askToChooseCardsAndPlayers(
        player,
        {
          min_num = 1,
          max_num = 1,
          min_card_num = 2,
          max_card_num = 2,
          targets = room:getOtherPlayers(player, false),
          pattern = ".|.|.|hand",
          skill_name = skillName,
          prompt = "#ol__xingwu-discard",
          cancelable = false,
          will_throw = true,
        }
      )

      if #plist > 0 and #cids > 0 then
        to = plist[1]
        player:turnOver()
        if player:isAlive() then
          room:throwCard(cids, skillName, player, player)
        end
      end
    end

    if to and to:isAlive() then
      room:throwCard(to:getCardIds("e"), skillName, to, player)

      if not (player:isMale() or player:isFemale() or to:isAlive()) then
        return false
      end

      room:damage{
        from = player,
        to = to,
        damage = to:isMale() and 2 or 1,
        skillName = skillName,
      }
    end
  end,
})

return xingwu
