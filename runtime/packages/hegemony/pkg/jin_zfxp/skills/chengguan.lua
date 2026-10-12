
local chengguan = fk.CreateSkill {
  name = "heg__chengguan",
}

Fk:loadTranslationTable{
  ["heg__chengguan"] = "承冠",
  [":heg__chengguan"] = "当你受到伤害后，若此次为你本回合首次受到的伤害，你可以与一名其他角色交换手牌；若不为首次，伤害来源可以与你交换手牌。",

  ["#heg__chengguan-choose"] = "承冠：你可以与一名其他角色交换手牌",
  ["#heg__chengguan-invoke"] = "承冠：是否与 %src 交换手牌？",
}

chengguan:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function (self, event, target, player, data)
    if target == player and player:hasSkill(chengguan.name) then
      local damage_event = player.room.logic:getActualDamageEvents(1, function(e)
        return e.data.to == player
      end)[1]
      if damage_event and damage_event.data == data then
        if #player.room:getOtherPlayers(player, false) == 0 then return end
        return not player:isKongcheng() or
          table.find(player.room:getOtherPlayers(player, false), function (p)
            return not p:isKongcheng()
          end)
      else
        return data.from and not data.from.dead and data.from ~= player and
        not (player:isKongcheng() and data.from:isKongcheng()) and player:hasShownSkill(chengguan.name)
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local damage_event = room.logic:getActualDamageEvents(1, function(e)
      return e.data.to == player
    end)[1]
    if damage_event and damage_event.data == data then
      local targets = room:getOtherPlayers(player, false)
      if player:isKongcheng() then
        targets = table.filter(room:getOtherPlayers(player, false), function (p)
          return not p:isKongcheng()
        end)
      end
      local to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        skill_name = chengguan.name,
        prompt = "#heg__chengguan-choose",
        cancelable = true,
      })
      if #to > 0 then
        event:setCostData(self, { tos = to })
        return true
      end
    else
      if room:askToSkillInvoke(data.from, {
        skill_name = chengguan.name,
        prompt = "#heg__chengguan-invoke:"..player.id,
      }) then
        event:setCostData(self, nil)
        room:doIndicate(data.from, { player })
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event:getCostData(self) then
      local to = event:getCostData(self).tos[1]
      room:swapAllCards(player, { player, to }, chengguan.name)
    else
      room:swapAllCards(data.from, { player, data.from }, chengguan.name)
    end
  end,
})

return chengguan
