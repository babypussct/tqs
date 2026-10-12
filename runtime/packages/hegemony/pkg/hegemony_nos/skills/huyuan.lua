
local huyuan = fk.CreateSkill{
  name = "nos_heg__huyuan",
}

Fk:loadTranslationTable{
  ["nos_heg__huyuan"] = "护援",
  [":nos_heg__huyuan"] = "结束阶段，你可以将一张装备牌置入一名角色的装备区，然后你可以弃置该角色距离为1的一名角色的一张牌。",

  ["#nos_heg__huyuan-invoke"] = "护援：你可以将一张装备牌置入一名角色的装备区",
  ["#nos_heg__huyuan-discard"] = "护援：你可以弃置 %dest 距离为1一名角色的一张牌",

  ["$nos_heg__huyuan1"] = "",
  ["$nos_heg__huyuan2"] = "",
}

huyuan:addAuxActiveSkill("#nos_heg__huyuan_active", {
  card_num = 1,
  target_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and #selected_cards == 1 and
      to_select:canMoveCardIntoEquip(selected_cards[1], false)
  end,
})

huyuan:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(huyuan.name) and player.phase == Player.Finish and
      not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "#nos_heg__huyuan_active",
      prompt = "#nos_heg__huyuan-invoke",
      cancelable = true,
    })
    if success and dat then
      event:setCostData(self, { tos = dat.targets, cards = dat.cards })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:moveCardIntoEquip(to, event:getCostData(self).cards, huyuan.name, false, player)
    if player.dead or to.dead then return end
    local targets = table.filter(room.alive_players, function (p)
      return p:distanceTo(to) == 1 and not p:isNude()
    end)
    if table.contains(targets, player) then
      if not table.find(player:getCardIds("he"), function (id)
        return player:prohibitDiscard(id)
      end) then
        table.removeOne(targets, player)
      end
    end
    local p = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#nos_heg__huyuan-discard::" .. to.id,
      skill_name = huyuan.name,
      cancelable = true,
    })
    if #p == 0 then return end
    p = p[1]
    if p == player then
      room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = huyuan.name,
        cancelable = false,
      })
    else
      local id = room:askToChooseCard(player, {
        target = p,
        flag = "he",
        skill_name = huyuan.name,
      })
      room:throwCard(id, huyuan.name, p, player)
    end
  end,
})

return huyuan
