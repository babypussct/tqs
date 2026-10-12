local xingshang = fk.CreateSkill {
  name = "os_mou__xingshang",
}

Fk:loadTranslationTable {
  ["os_mou__xingshang"] = "行殇",
  [":os_mou__xingshang"] = "一名角色死亡时，你可以将其区域内的所有牌分配给任意角色；出牌阶段结束时，你可将一名角色区域内的牌数弃置至X张，" ..
      "然后你可使用其中至多X张因此弃置的牌（X为其体力值，且以此法使用的牌不计入次数限制）。",

  ["#os_mou__xingshang-invoke"] = "行殇：你可将 %dest 区域内的所有牌分配给任意角色",
  ["#os_mou__xingshang-choose"] = "行殇：你可将一名角色区域内的牌数弃置至与其体力值相等",
  ["#os_mou__xingshang-discard"] = "行殇：请选择 %dest 区域内的%arg张牌弃置",
  ["#os_mou__xingshang-use"] = "行殇：你可使用其中一张牌（还可使用%arg张）",

  ["$os_mou__xingshang1"] = "生已辜七尺之形，死又岂能再负此一棺之土！",
  ["$os_mou__xingshang2"] = "汝若怀尽忠之心，生死又有何论？",
}

xingshang:addEffect(fk.Death, {
  can_trigger = function(self, event, target, player, data)
    return not target:isAllNude() and player:hasSkill(xingshang.name)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(
      player,
      { skill_name = xingshang.name, prompt = "#os_mou__xingshang-invoke::" .. target.id }
    )
  end,
  on_use = function(self, event, target, player, data)
    local toGive = target:getCardIds("hej")
    player.room:askToYiji(
      player,
      {
        min_num = #toGive,
        max_num = #toGive,
        cards = toGive,
        targets = player.room:getAlivePlayers(),
        skill_name = xingshang.name,
        expand_pile = toGive,
      }
    )
  end,
})

xingshang:addEffect(fk.EventPhaseEnd, {
  can_trigger = function(self, event, target, player, data)
    return
        target == player and
        player.phase == Player.Play and
        player:hasSkill(xingshang.name) and
        table.find(player.room.alive_players, function(p)
          return #p:getCardIds("hej") > math.max(0, p.hp)
        end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(
      room.alive_players,
      function(p)
        return #p:getCardIds("hej") > math.max(0, p.hp)
      end
    )

    if #targets == 0 then
      return false
    end

    local tos = room:askToChoosePlayers(
      player,
      {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = xingshang.name,
        prompt = "#os_mou__xingshang-choose",
      }
    )

    if #tos > 0 then
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = xingshang.name
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local x = math.max(0, to.hp)
    local num = #to:getCardIds("hej") - x

    local ids
    if to == player then
      local hand = table.filter(player:getCardIds("h"), function(id)
        return not player:prohibitDiscard(id)
      end)
      local equipments = table.filter(player:getCardIds("e"), function(id)
        return not player:prohibitDiscard(id)
      end)
      local judge = player:getCardIds("j")

      num = math.min(num, #hand + #equipments + #judge)
      if num < 1 then
        return false
      end

      local cardData = {}
      if #hand > 0 then
        table.insert(cardData, { "$Hand", hand })
      end
      if #equipments > 0 then
        table.insert(cardData, { "$Equip", equipments })
      end
      if #judge > 0 then
        table.insert(cardData, { "$Judge", judge })
      end

      ids = room:askToChooseCards(
        player,
        {
          min = num,
          max = num,
          target = player,
          flag = { card_data = cardData },
          skill_name = skillName,
          prompt = "#os_mou__xingshang-discard::" .. player.id .. ":" .. num,
        }
      )
    else
      ids = room:askToChooseCards(
        player,
        {
          min = num,
          max = num,
          target = to,
          flag = "hej",
          skill_name = skillName,
          prompt = "#os_mou__xingshang-discard::" .. player.id .. ":" .. num,
        }
      )
    end

    room:throwCard(ids, skillName, to, player)

    local toUse = table.filter(ids, function(id)
      return room:getCardArea(id) == Card.DiscardPile
    end)
    while #toUse > 0 and x > 0 do
      local use = room:askToUseRealCard(
        player,
        {
          pattern = toUse,
          prompt = "#os_mou__xingshang-use:::" .. x,
          skill_name = skillName,
          expand_pile = toUse,
          skip = true,
          extra_data = {
            bypass_times = false,
            extraUse = true,
          }
        }
      )

      if not use then
        break
      end

      table.removeOne(ids, use.card.id)
      room:useCard(use)

      if not player:isAlive() then
        break
      end

      toUse = table.filter(ids, function(id)
        return room:getCardArea(id) == Card.DiscardPile
      end)
      x = x - 1
    end
  end,
})

return xingshang
