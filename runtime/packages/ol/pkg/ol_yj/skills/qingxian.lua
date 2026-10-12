local qingxian = fk.CreateSkill{
  name = "ol__qingxian",
}

Fk:loadTranslationTable{
  ["ol__qingxian"] = "清弦",
  [":ol__qingxian"] = "当你受到伤害/回复体力后，若没有角色处于濒死状态，你可以选择一项令伤害来源/一名其他角色执行：1.失去1点体力并"..
  "随机使用牌堆一张装备牌；2.回复1点体力并弃置一张装备牌。若其使用或弃置的牌花色为♣，你摸一张牌。",

  ["#ol__qingxian-invoke"] = "清弦：你可以令 %dest 执行一项",
  ["#ol__qingxian-choose"] = "清弦：你可以令一名角色执行一项",
  ["ol__qingxian_losehp"] = "失去1点体力，使用随机装备",
  ["ol__qingxian_recover"] = "回复1点体力，弃置一张装备",

  ["$ol__qingxian1"] = "弦音之妙，尽在无心。",
  ["$ol__qingxian2"] = "流水清音听，高山弦拨心。",
}

qingxian:addAuxActiveSkill("ol__qingxian_active", {
  card_num = 0,
  target_num = 1,
  interaction = UI.OptionBox { options = { "ol__qingxian_losehp", "ol__qingxian_recover" }, direct_send = true },
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player
  end,
  refresh_interaction = function(self, player, selected_cards, selected_targets, extra_data)
    if #selected_targets > 0 then
      if selected_targets[1]:isWounded() then
        return { "ol__qingxian_losehp", "ol__qingxian_recover" }
      end
      return{ "ol__qingxian_losehp" }
    end
    return {}
  end
})

local spec = {
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local choice = event:getCostData(self).choice
    local yes = false
    if choice == "ol__qingxian_losehp" then
      room:loseHp(to, 1, qingxian.name)
      if to.dead then return end
      local cards = table.filter(room.draw_pile, function (id)
        local card = Fk:getCardById(id)
        return card.type == Card.TypeEquip and to:canUseTo(card, to)
      end)
      if #cards > 0 then
        local card = Fk:getCardById(room:tableRandomPick(cards))
        yes = card.suit == Card.Club
        room:useCard{
          from = to,
          tos = {to},
          card = card,
        }
      end
    else
      if to:isWounded() then
        room:recover{
          who = to,
          num = 1,
          recoverBy = player,
          skillName = qingxian.name,
        }
      end
      if not to.dead and not to:isNude() then
        local card = room:askToDiscard(to, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = qingxian.name,
          cancelable = false,
          pattern = ".|.|.|.|.|equip",
          skip = true,
        })
        if #card > 0 then
          yes = Fk:getCardById(card[1]).suit == Card.Club
          room:throwCard(card, qingxian.name, to, to)
        end
      end
    end
    if yes and not player.dead then
      player:drawCards(1, qingxian.name)
    end
  end,
}

qingxian:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(qingxian.name) and
      data.from and not data.from.dead and
      not table.find(player.room.alive_players, function(p)
        return p.dying
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local choices = { "ol__qingxian_losehp", "Cancel" }
    if data.from:isWounded() then
      table.insert(choices, "ol__qingxian_recover")
    end
    local choice = player.room:askToChoice(player, {
      choices = choices,
      skill_name = qingxian.name,
      all_choices = { "ol__qingxian_losehp", "ol__qingxian_recover", "Cancel" },
      prompt = "#ol__qingxian-invoke::"..data.from.id,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, { tos = { data.from }, choice = choice })
      return true
    end
  end,
  on_use = spec.on_use,
})
qingxian:addEffect(fk.HpRecover, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qingxian.name) and
      not table.find(player.room.alive_players, function(p)
        return p.dying
      end) and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "ol__qingxian_active",
      prompt = "#ol__qingxian-choose",
      cancelable = true,
    })
    if success and dat then
      event:setCostData(self, {tos = dat.targets, choice = dat.interaction})
      return true
    end
  end,
  on_use = spec.on_use,
})

return qingxian
