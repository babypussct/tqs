local osLingbao = fk.CreateSkill {
  name = "os__lingbao"
}

Fk:loadTranslationTable{
  ["os__lingbao"] = "灵宝",
  [":os__lingbao"] = "出牌阶段，你可以移去两张花色不同的“丹”并摸两张牌，若移去的牌：均为红色，你令一名角色从牌堆中获得两张基本牌；" ..
  "均为黑色，你弃置一名角色区域内的一张牌；颜色不同，你令一名角色摸一张牌，另一名角色弃置一张牌。然后若你本回合移去过花色相同的“丹”，此技能本回合失效。",

  ["#os__lingbao"] = "灵宝：移去两张不同花色的“丹”并摸两张牌，根据颜色执行效果。<br/>若你本回合移去过花色相同的“丹”，此技能本回合失效",
  ["#os__lingbao-red_red"] = "灵宝：选择一名角色，令其从牌堆中获得两张基本牌",
  ["#os__lingbao-black_black"] = "灵宝：选择一名角色，弃置其区域内一张牌",
  ["#os__lingbao-black_red"] = "灵宝：选择一名角色摸一张牌，另一名角色弃置一张牌",
  ["#os__lingbao-red"] = "灵宝：再选一张红色“丹”以令一名角色从牌堆中获得两张基本牌，<br/>或一张黑色“丹”以令一名角色摸一张牌，另一名角色弃置一张牌",
  ["#os__lingbao-black"] = "灵宝：再选一张黑色“丹”以弃置一名角色区域内一张牌，<br/>或一张红色“丹”以令一名角色摸一张牌，另一名角色弃置一张牌",

  ["@[suits]os__lingbao-turn"] = "灵宝",
  ["#os__lingbao-obtain"] = "灵宝：选择一名角色，令其从牌堆中获得两张基本牌",
  ["#os__lingbao-throw"] = "灵宝：选择一名角色，弃置其区域内一张牌",
  ["#os__lingbao-discard"] = "灵宝：弃置%dest区域内一张牌",
  ["#os__lingbao-draw_discard"] = "灵宝：选择两名角色，先选的摸一张牌，后选的弃置一张牌",

  ["$os__lingbao1"] = "洞明于至道，俯弘于世教。",
  ["$os__lingbao2"] = "凝神太虚镜，北冥探玄珠。",
}

osLingbao:addEffect("active", {
  can_use = function(self, player)
    return #player:getPile("os__cinnabar") > 1
  end,
  prompt = function (self, player, selected_cards, selected_targets)
    if #selected_cards == 2 then
      local color = table.map(selected_cards, function(id) return Fk:getCardById(id).color end)
      if color[1] == color[2] then
        return color[1] == Card.Red and "#os__lingbao-red_red" or "#os__lingbao-black_black"
      else
        return "#os__lingbao-black_red"
      end
    elseif #selected_cards == 1 then
      return "#os__lingbao-" .. (Fk:getCardById(selected_cards[1]).color == Card.Red and "red" or "black")
    end
    return "#os__lingbao"
  end,
  card_num = 2,
  expand_pile = "os__cinnabar",
  card_filter = function(self, player, to_select, selected)
    if #selected < 2 and table.contains(player:getPile("os__cinnabar"), to_select) then
      if #selected == 0 then
        return Fk:getCardById(to_select).suit ~= Card.NoSuit
      else
        return Fk:getCardById(to_select):compareSuitWith(Fk:getCardById(selected[1]), true)
      end
    end
  end,
  target_num = 0,
  on_use = function(self, room, use)
    ---@type string
    local skillName = osLingbao.name
    if #use.cards ~= 2 then
      return
    end

    local player = use.from
    room:moveCardTo(use.cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, skillName, "os__cinnabar", true, player)
    local color = table.map(use.cards, function(id) return Fk:getCardById(id).color end)
    local suits = table.map(use.cards, function(id) return Fk:getCardById(id).suit end)
    local remaining = table.map(player:getPile("os__cinnabar"), function(id)
      return Fk:getCardById(id).suit
    end)
    player.room:setPlayerMark(player, "@[suits]os__cinnabar", #remaining > 0 and remaining or 0) -- 宝宝。不改造私人牌堆显示的方法
    if player:isAlive() then player:drawCards(2, skillName) end
    if player.dead then return end
    if color[1] == color[2] then
      if color[1] == Card.Red then
        local target = room:askToChoosePlayers(
          player,
          {
            targets = room.alive_players,
            min_num = 1,
            max_num = 1,
            prompt = "#os__lingbao-obtain",
            skill_name = skillName,
            cancelable = false,
          }
        )
        if #target > 0 then
          local cards = room:getCardsFromPileByRule(".|.|.|.|.|basic", 2, "drawPile")
          if #cards > 0 then
            room:obtainCard(target[1], cards, false, fk.ReasonPrey, player, skillName)
          end
        end
      else
        local availableTargets = table.filter(room.alive_players, function(p)
          return not p:isAllNude()
        end)
        if #availableTargets == 0 then
          return false
        end

        local tos = room:askToChoosePlayers(
          player,
          {
            targets = availableTargets,
            min_num = 1,
            max_num = 1,
            prompt = "#os__lingbao-throw",
            skill_name = skillName,
            cancelable = false,
          }
        )
        if #tos > 0 then
          local to = tos[1]
          room:throwCard(room:askToChooseCard(player, {
            target = to,
            flag = "hej",
            min_num = 1,
            max_num = 1,
            skill_name = skillName,
            cancelable = false,
            prompt = "#os__lingbao-discard::" .. to.id,
          }), skillName, to, player)
        end
      end
    else
      local targets = room:askToChoosePlayers(
        player,
        {
          targets = room:getAlivePlayers(false),
          min_num = 2,
          max_num = 2,
          prompt = "#os__lingbao-draw_discard",
          skill_name = skillName,
          cancelable = false,
          target_tip_name = "os__lingbao-tip"
        }
      )
      if #targets > 0 then
        targets[1]:drawCards(1, skillName)
        local to = targets[2]
        if not to:isNude() then
          room:askToDiscard(
            to,
            {
              min_num = 1,
              max_num = 1,
              include_equip = true,
              skill_name = skillName,
              cancelable = false,
            }
          )
        end
      end
    end
    for _, s in ipairs(suits) do
      if not room:addTableMarkIfNeed(player, "@[suits]os__lingbao-turn", s) then
        room:invalidateSkill(player, skillName, "-turn", skillName)
      end
    end
  end,
})

Fk:addTargetTip{
  name = "os__lingbao-tip",
  target_tip = function(self, player, to_select, selected, _, _, selectable)
    if not selectable then return end
    if #selected == 0 or (#selected > 0 and selected[1] == to_select) then
      return "draw_card"
    else
      return "discard_skill"
    end
  end,
}

return osLingbao
