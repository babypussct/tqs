local tianshui = fk.CreateSkill {
  name = "peixiu_tianshui",
}

Fk:loadTranslationTable {
  ["peixiu_tianshui"] = "天水",
  [":peixiu_tianshui"] = "你获得此技能后，可以弃置一名角色一张手牌，若不为【杀】，你摸两张牌。",

  ["#peixiu_tianshui-choose"] = "天水：选择一名角色，弃置其一张手牌，若不为【杀】你摸两张牌",
}

tianshui:addEffect(fk.EventAcquireSkill, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(tianshui.name) and data.skill.name == tianshui.name and
      table.find(player.room.alive_players, function (p)
        return not p:isKongcheng()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return not p:isKongcheng()
    end)
    if table.contains(targets, player) and
      not table.find(player:getCardIds("h"), function (id)
        return not player:prohibitDiscard(id)
      end) then
      table.removeOne(targets, player)
    end
    if #targets == 0 then
      room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = tianshui.name,
        pattern = "false",
        prompt = "#peixiu_tianshui-choose",
        cancelable = true,
      })
    else
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = tianshui.name,
        prompt = "#peixiu_tianshui-choose",
        cancelable = true,
      })
      if #to > 0 then
        event:setCostData(self, { tos = to })
        return true
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local card, yes
    if to == player then
      card = room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = tianshui.name,
        cancelable = false,
        skip = true,
      })
      yes = Fk:getCardById(card[1]).trueName ~= "slash"
      room:throwCard(card, tianshui.name, player, player)
    else
      card = room:askToChooseCard(player, {
        target = to,
        flag = "he",
        skill_name = tianshui.name,
      })
      yes = Fk:getCardById(card).trueName ~= "slash"
      room:throwCard(card, tianshui.name, to, player)
    end
    if yes and not player.dead then
      player:drawCards(2, tianshui.name)
    end
  end,
})

return tianshui
