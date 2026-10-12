local shezi = fk.CreateSkill {
  name = "shezi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["shezi"] = "摄梓",
  [":shezi"] = "锁定技，准备阶段，你选择一名角色并选择其一个区域，若其此区域内有装备牌，你获得其此区域里的所有牌。",

  ["#shezi-choose"] = "摄梓：选择一名角色，若其指定区域中有装备牌则获得其该区域的所有牌",
  ["#shezi-choice"] = "摄梓：选择 %dest 一个区域，若其指定区域中有装备牌则获得其该区域的所有牌",

  ["$shezi1"] = "成为我的一部分吧！",
  ["$shezi2"] = "一切都围着我运行！",
}

shezi:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shezi.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getAlivePlayers(false),
      skill_name = shezi.name,
      prompt = "#shezi-choose",
      cancelable = false,
    })[1]
    local choice = room:askToChoice(player, {
      choices = { "$Hand", "$Equip", "$Judge" },
      skill_name = shezi.name,
      prompt = "#shezi-choice::"..to.id,
    })
    local cards
    if choice == "$Hand" then
      if to == player then
        return false
      end

      cards = to:getCardIds("h")
    elseif choice == "$Equip" then
      cards = to:getCardIds("e")
    elseif choice == "$Judge" then
      cards = to:getCardIds("j")
    end
    if table.find(cards, function (id)
      return Fk:getCardById(id).type == Card.TypeEquip
    end) then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, shezi.name, nil, false, player)
    end
  end,
})

return shezi
