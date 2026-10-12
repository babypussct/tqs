
local shenzhi = fk.CreateSkill{
  name = "hs__shenzhi",
}

Fk:loadTranslationTable{
  ["hs__shenzhi"] = "神智",
  [":hs__shenzhi"] = "准备阶段，你可以弃置一名角色一个区域内的最后一张牌，然后其回复1点体力。",

  ["#hs__shenzhi-choose"] = "神智：弃置一名角色一个区域内的最后一张牌，其回复1点体力",

  ["$hs__shenzhi1"] = "子龙将军，一切都托付给你了。",
  ["$hs__shenzhi2"] = "阿斗，相信妈妈，没事的。",
}

shenzhi:addAuxActiveSkill("#hs__shenzhi_active", {
  card_num = 0,
  target_num = 1,
  interaction = UI.OptionBox { options = { "$Hand", "$Equip", "$Judge" }, direct_send = true },
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected, selected_cards, card, extra_data)
    return #selected == 0 and
      table.find({ "h", "e", "j" }, function (area)
        return #to_select:getCardIds(area) == 1 and not player:prohibitDiscard(to_select:getCardIds(area)[1])
      end)
  end,
  refresh_interaction = function (self, player, selected_cards, selected_targets, extra_data)
    if #selected_targets == 1 then
      local choices = {}
      if selected_targets[1]:getHandcardNum() == 1 and
        not player:prohibitDiscard(selected_targets[1]:getCardIds("h")[1]) then
        table.insert(choices, "$Hand")
      end
      if #selected_targets[1]:getCardIds("e") == 1 then
        table.insert(choices, "$Equip")
      end
      if #selected_targets[1]:getCardIds("j") == 1 then
        table.insert(choices, "$Judge")
      end
      return choices
    else
      return {}
    end
  end,
})

shenzhi:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shenzhi.name) and player.phase == Player.Start and
      table.find(player.room.alive_players, function(p)
        return #p:getCardIds("h") == 1 or #p:getCardIds("e") == 1 or #p:getCardIds("j") == 1
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "#hs__shenzhi_active",
      prompt = "#hs__shenzhi-choose",
      cancelable = true,
    })
    if success and dat then
      event:setCostData(self, { tos = dat.targets, choice = dat.interaction })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local choice = event:getCostData(self).choice
    if choice == "$Hand" then
      room:throwCard(to:getCardIds("h"), shenzhi.name, to, player)
    elseif choice  == "$Equip" then
      room:throwCard(to:getCardIds("e"), shenzhi.name, to, player)
    else
      room:throwCard(to:getCardIds("j"), shenzhi.name, to, player)
    end
    if not to.dead then
      room:recover{
        who = to,
        num = 1,
        recoverBy = player,
        skillName = shenzhi.name,
      }
    end
  end,
})

return shenzhi