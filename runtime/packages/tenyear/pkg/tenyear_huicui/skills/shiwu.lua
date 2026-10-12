
local shiwu = fk.CreateSkill({
  name = "shiwu",
})

Fk:loadTranslationTable{
  ["shiwu"] = "恃武",
  [":shiwu"] = "其他角色回合开始，你可视为对其使用【决斗】，若你对其造成伤害，你从牌堆中获得一张伤害牌，"..
  "若其对你造成伤害，其获得〖持剑〗，你失去〖持剑〗直至其回合结束。杀死你的角色获得〖持剑〗。",

  ["#shiwu-invoke"] = "恃武：你可以视为对 %dest 使用【决斗】",

  ["$shiwu1"] = "唔！剑你背过吗？人你杀过吗？",
  ["$shiwu2"] = "唔！这叫实力！你懂吗！",
}

shiwu:addEffect(fk.TurnStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(shiwu.name) and
      not target.dead and player:canUseTo(Fk:cloneCard("duel"), target)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = shiwu.name,
      prompt = "#shiwu-invoke::"..target.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local use = room:useVirtualCard("duel", nil, player, target, shiwu.name, true)
    if use and use.damageDealt then
      if use.damageDealt[target] and not player.dead then
        local cards = table.filter(room.draw_pile, function (id)
          return Fk:getCardById(id).is_damage_card
        end)
        if #cards > 0 then
          room:moveCardTo(room:tableRandomPick(cards), Card.PlayerHand, player, fk.ReasonJustMove, shiwu.name, nil, false, player)
        end
      elseif use.damageDealt[player] and not target.dead then
        room:addTableMarkIfNeed(target, shiwu.name, player)
        room:handleAddLoseSkills(target, "chijian")
        room:handleAddLoseSkills(player, "-chijian")
      end
    end
  end,
})

shiwu:addEffect(fk.TurnEnd, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return table.contains(target:getTableMark(shiwu.name), player)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:removeTableMark(target, shiwu.name, player)
    room:handleAddLoseSkills(target, "-chijian")
    room:handleAddLoseSkills(player, "chijian")
  end,
})

shiwu:addEffect(fk.Death, {
  anim_type = "negative",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(shiwu.name, false, true) and
      data.killer and not data.killer.dead
  end,
  on_use = function(self, event, target, player, data)
    player.room:handleAddLoseSkills(data.killer, "chijian")
  end,
})

return shiwu
