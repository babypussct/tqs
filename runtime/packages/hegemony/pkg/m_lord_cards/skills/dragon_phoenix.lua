
local skill = fk.CreateSkill{
  name = "#mobile__dragon_phoenix_skill",
  attached_equip = "mobile__dragon_phoenix",
}

local H = require "packages.hegemony.util"

skill:addEffect(fk.Damage, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(skill.name) and
      data.card and data.card.trueName == "slash" and data.by_user then
      local damage_events = player.room.logic:getActualDamageEvents(1, function (e)
        return e.data.from == player and e.data.card and e.data.card.trueName == "slash" and e.data.by_user
      end, Player.HistoryTurn)
      if #damage_events == 1 and damage_events[1].data == data then
        return data.to:getMark("@!!yinyangfish") > 0 or not data.to:isKongcheng()
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    if data.to:getMark("@!!yinyangfish") > 0 then
      table.insert(choices, "@!!yinyangfish")
    end
    if not data.to:isKongcheng() then
      table.insert(choices, "hand_card")
    end
    local choice = room:askToChoice(player, {
      skill_name = skill.name,
      prompt = "#mobile__dragon_phoenix-invoke::"..data.to.id,
      choices = choices,
      cancelable = true,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, { tos = { data.to }, choice = choice })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    if choice == "@!!yinyangfish" then
      H.removeHegMark(room, data.to, "yinyangfish", 1)
      H.addHegMark(player, "yinyangfish", 1)
    else
      local card = room:askToChooseCard(player, {
        target = data.to,
        flag = "h",
        skill_name = skill.name,
      })
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, skill.name, nil, false, player)
    end
  end,
})

return skill
