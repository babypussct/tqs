local chunhui = fk.CreateSkill{
  name = "chunhui",
  tags = { Skill.Compulsory },
  dynamic_desc = function (self, player, lang)
    if player:getMark("chunhui") > 0 then
      return "chunhui_inner"
    end
  end,
}

Fk:loadTranslationTable{
  ["chunhui"] = "春晖",
  [":chunhui"] = "锁定技，准备阶段或当你受到伤害后，令一名角色交给你一张手牌。若此牌为黑色，本回合你或其下一次成为红色牌的目标时，"..
  "各弃置一张手牌。",

  [":chunhui_inner"] = "锁定技，准备阶段或当你受到伤害后，令一名角色交给你一张手牌。若此牌为黑色，本回合你或其下一次成为黑色牌的目标时，"..
  "各弃置一张手牌。",

  ["#chunhui-choose"] = "春晖：令一名角色交给你一张手牌，若为黑色则双方需弃置手牌",
  ["#chunhui-give"] = "春晖：请交给 %src 一张手牌，若为黑色则双方需弃置手牌",

  ["$chunhui1"] = "翩翩蝶儿舞流连，缓缓上云间。",
  ["$chunhui2"] = "渺渺涟骑一圈点，摇漾春如线。",
}

local spec = {
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return not p:isNude()
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = chunhui.name,
      prompt = "#chunhui-choose",
      cancelable = false,
    })[1]
    local cards = room:askToCards(to, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = chunhui.name,
      prompt = "#chunhui-give:"..player.id,
      cancelable = false,
    })
    local yes = Fk:getCardById(cards[1]).color == Card.Black
    room:obtainCard(player, cards, false, fk.ReasonGive, to, chunhui.name)
    if yes and not player.dead then
      room:addTableMarkIfNeed(player, "chunhui-turn", to)
    end
  end,
}

chunhui:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(chunhui.name) and player.phase == Player.Start and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return not p:isNude()
      end)
  end,
  on_use = spec.on_use,
})

chunhui:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(chunhui.name) and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return not p:isNude()
      end)
  end,
  on_use = spec.on_use,
})

chunhui:addEffect(fk.TargetConfirming, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return table.contains(player:getTableMark("chunhui-turn"), data.to) and
      player:getMark(chunhui.name) + data.card.color == 2
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:removeTableMark(player, "chunhui-turn", data.to)
    room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = chunhui.name,
      cancelable = false,
    })
    room:askToDiscard(data.to, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = chunhui.name,
      cancelable = false,
    })
  end,
})

chunhui:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, chunhui.name, 0)
end)

return chunhui
