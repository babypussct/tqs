local canyun = fk.CreateSkill{
  name = "mobile__canyun",
}

Fk:loadTranslationTable{
  ["mobile__canyun"] = "残韵",
  [":mobile__canyun"] = "出牌阶段限一次，你可以选择至多X名其他角色并弃置等量的牌（X为你的体力值，每名角色每局游戏限一次），"..
  "若这些角色装备区内的牌数：小于你，其回复1点体力；大于你，其失去1点体力；等于你，其摸一张牌。若你选择的目标数等于X，你摸一张牌。",
}

canyun:addEffect("active", {
  anim_type = "control",
  prompt = "#mobile__qingxian",
  min_card_num = 1,
  min_target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(canyun.name, Player.HistoryPhase) == 0 and player.hp > 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < player.hp and not player:prohibitDiscard(to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return to_select ~= player and #selected < #selected_cards and
      not table.contains(player:getTableMark(canyun.name), to_select.id)
  end,
  target_tip = function (self, player, to_select, selected, selected_cards, card, selectable, extra_data)
    if not selectable then return nil end
    if #to_select:getCardIds("e") < #player:getCardIds("e") then
      return { {content = "heal_hp", type = "normal"} }
    elseif #to_select:getCardIds("e") == #player:getCardIds("e") then
      return { {content = "draw1", type = "normal"} }
    elseif #to_select:getCardIds("e") > #player:getCardIds("e") then
      return { {content = "lose_hp", type = "warning"} }
    end
  end,
  feasible = function(self, player, selected, selected_cards)
    return #selected >= 1 and #selected == #selected_cards
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:sortByAction(effect.tos)
    local mark = player:getTableMark(canyun.name)
    for _, p in ipairs(effect.tos) do
      table.insert(mark, p.id)
    end
    room:setPlayerMark(player, canyun.name, mark)
    local numMap = {}
    for _, p in ipairs(effect.tos) do
      numMap[p.id] = #p:getCardIds("e") - #player:getCardIds("e")
    end
    local draw = #effect.tos == player.hp
    room:throwCard(effect.cards, canyun.name, player, player)
    for _, p in ipairs(effect.tos) do
      if not p.dead then
        if numMap[p.id] > 0 then
          room:loseHp(p, 1, canyun.name)
        elseif numMap[p.id] == 0 then
          p:drawCards(1, canyun.name)
        else
          room:recover {
            num = 1,
            skillName = canyun.name,
            who = p,
            recoverBy = player,
          }
        end
      end
    end
    if draw and not player.dead then
      player:drawCards(1, canyun.name)
    end
  end,
})

return canyun
