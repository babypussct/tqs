local shawu = fk.CreateSkill {
  name = "shawu",
}

Fk:loadTranslationTable{
  ["shawu"] = "沙舞",
  [":shawu"] = "当你使用【杀】指定目标后，你可以弃置两张手牌或1枚“沙”标记对目标角色造成1点伤害。若你弃置的是“沙”标记，你摸两张牌。",

  ["#shawu-invoke"] = "沙舞：你可执行一项，对 %dest 造成1点伤害",
  ["shawu_discard"] = "弃置两张牌",
  ["shawu_remove"] = "移去1枚“沙”标记"
}

shawu:addAuxActiveSkill("shawu_active", {
  interaction = function(self, player)
    local choices = { "shawu_discard", "shawu_remove" }
    if player:getMark("@xiaowu_sand") == 0 then
      table.remove(choices, 2)
    end

    return UI.ComboBox { choices = choices, all_choices = { "shawu_discard", "shawu_remove" } }
  end,
  card_num = function(self, player)
    return self.interaction.data == "shawu_discard" and 2 or 0
  end,
  target_num = 0,
  card_filter = function(self, player, to_select, selected)
    if self.interaction.data == "shawu_discard" then
      return
        #selected < 2 and
        Fk:currentRoom():getCardArea(to_select) == Card.PlayerHand and
        not player:prohibitDiscard(to_select)
    end
    return false
  end,
})

shawu:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shawu.name) and data.card.trueName == "slash" and
      (player:getMark("@xiaowu_sand") > 0 or player:getHandcardNum() > 1) and
      not data.to.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "shawu_active",
      prompt = "#shawu-invoke::" .. data.to.id,
    })
    if success and dat then
      event:setCostData(self, {tos = {data.to}, cards = dat.cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local draw2 = false
    if #event:getCostData(self).cards > 1 then
      room:throwCard(event:getCostData(self).cards, shawu.name, player, player)
    else
      room:removePlayerMark(player, "@xiaowu_sand")
      draw2 = true
    end
    if not data.to.dead then
      room:damage{
        from = player,
        to = data.to,
        damage = 1,
        skillName = shawu.name,
      }
    end
    if draw2 and not player.dead then
      player:drawCards(2, shawu.name)
    end
  end,
})

return shawu
