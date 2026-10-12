
local lianyou = fk.CreateSkill {
  name = "lianyou",
  max_branches_use_time = {
    ["lianyou_recover"] = {
      [Player.HistoryRound] = 1,
    },
    ["lianyou_equip"] = {
      [Player.HistoryRound] = 1,
    },
    ["lianyou_draw"] = {
      [Player.HistoryRound] = 1,
    },
  },
}

Fk:loadTranslationTable{
  ["lianyou"] = "怜幼",
  [":lianyou"] = "每轮每项限一次，你的回合开始或你受到伤害后，你可以选择一项："..
  "1.令一名角色回复1点体力；2.令一名角色随机使用牌堆或弃牌堆中两张装备牌；3.摸三张牌并可以交给一名其他角色三张牌。",

  ["#lianyou-invoke"] = "怜幼：你可以选择一项执行",
  ["lianyou_recover"] = "令一名角色回复1点体力",
  ["lianyou_equip"] = "令一名角色随机使用两张装备",
  ["lianyou_draw"] = "摸三张牌并可以交出三张牌",
  ["#lianyou-use"] = "怜幼：请使用%arg",
  ["#lianyou-give"] = "怜幼：你可以交给一名其他角色三张牌",

  ["$lianyou1"] = "莫惊，莫啼，阿娘守着你~",
  ["$lianyou2"] = "我儿入怀，方觉天下皆安。",
}

lianyou:addAuxActiveSkill("#lianyou_active", {
  card_num = 0,
  min_target_num = 0,
  max_target_num = 1,
  interaction = function(self, player)
    local choices, all_choices = {}, {}
    for _, choice in ipairs({ "lianyou_recover", "lianyou_equip", "lianyou_draw" }) do
      table.insert(all_choices, choice)
      if lianyou:withinBranchTimesLimit(player, choice, Player.HistoryRound) then
        table.insert(choices, choice)
      end
    end
    return UI.ComboBox { choices = choices, all_choices = all_choices }
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected == 0 then
      if self.interaction.data == "lianyou_recover" then
        return to_select:isWounded() --and
          --table.every(Fk:currentRoom().alive_players, function(p)
          --  return p.hp >= to_select.hp
          --end)
      elseif self.interaction.data == "lianyou_equip" then
        return true
          --table.every(Fk:currentRoom().alive_players, function(p)
          --  return #p:getCardIds("e") >= #to_select:getCardIds("e")
          --end)
      elseif self.interaction.data == "lianyou_draw" then
        return false
      end
    end
  end,
  feasible = function(self, player, selected, selected_cards, card)
    if self.interaction.data == "lianyou_recover" then
      return #selected == 1
    elseif self.interaction.data == "lianyou_equip" then
      return #selected == 1
    elseif self.interaction.data == "lianyou_draw" then
      return #selected == 0
    end
  end,
})

local spec = {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(lianyou.name) and
      player:usedSkillTimes(lianyou.name, Player.HistoryRound) < 3
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "#lianyou_active",
      prompt = "#lianyou-invoke",
      cancelable = true,
      skip = true,
    })
    if success and dat then
      event:setCostData(self, { tos = dat.targets, choice = dat.interaction })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    player:addSkillBranchUseHistory(lianyou.name, choice, 1)
    if choice == "lianyou_recover" then
      local to = event:getCostData(self).tos[1]
      room:recover({
        who = to,
        num = 1,
        recoverBy = player,
        skillName = lianyou.name,
      })
    elseif choice == "lianyou_equip" then
      local to = event:getCostData(self).tos[1]
      local subtype
      for _ = 1, 2 do
        local cards = table.filter(room.draw_pile, function(id)
          local card = Fk:getCardById(id)
          return card.type == Card.TypeEquip and card.sub_type ~= subtype and to:canUse(card)
        end)
        if #cards > 0 then
          local card = Fk:getCardById(room:tableRandomPick(cards))
          subtype = card.sub_type
          if to:canUseTo(card, to) then
            room:useCard{
              from = to,
              tos = { to },
              card = card,
            }
          else
            room:askToUseRealCard(to, {
              pattern = { card.id },
              skill_name = lianyou.name,
              prompt = "#lianyou-use:::"..card:toLogString(),
              cancelable = false,
              expand_pile = { card.id },
            })
          end
        end
      end
    elseif choice == "lianyou_draw" then
      player:drawCards(3, lianyou.name)
      if #player:getCardIds("he") < 3 or #room:getOtherPlayers(player, false) == 0 then return end
      --local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      --  return table.every(room:getOtherPlayers(player, false), function (q)
      --    return p:getHandcardNum() <= q:getHandcardNum()
      --  end)
      --end)
      local to, cards = room:askToChooseCardsAndPlayers(player, {
        min_card_num = 3,
        max_card_num = 3,
        min_num = 1,
        max_num = 1,
        targets = room:getOtherPlayers(player, false),
        skill_name = lianyou.name,
        prompt = "#lianyou-give",
        cancelable = true,
      })
      if #to > 0 and #cards > 0 then
        room:moveCardTo(cards, Card.PlayerHand, to[1], fk.ReasonGive, lianyou.name, nil, false, player)
      end
    end
  end,
}
lianyou:addEffect(fk.TurnStart, spec)
lianyou:addEffect(fk.Damaged, spec)

return lianyou
