local rangjie = fk.CreateSkill {
  name = "rangjie",
}

Fk:loadTranslationTable{
  ["rangjie"] = "让节",
  [":rangjie"] = "当你受到1点伤害后，你可以选择一项：1.移动场上一张牌；2.从牌堆或弃牌堆中随机获得一张你指定类别的牌。最后你摸一张牌。",

  ["rangjie_move"] = "移动场上一张牌",
  ["rangjie_obtain"] = "获得指定类别的牌",
  ["#rangjie-move"] = "让节：请选择两名角色，移动其场上的一张牌",

  ["$rangjie1"] = "公既执掌权柄，又何必令君臣遭乱。",
  ["$rangjie2"] = "公虽权倾朝野，亦当尊圣上之意。",
}

rangjie:addEffect(fk.Damaged, {
  anim_type = "masochism",
  trigger_times = function(self, event, target, player, data)
    return data.damage
  end,
  on_cost = function(self, event, target, player, data)
    ---@type string
    local skillName = rangjie.name
    local choices = { "rangjie_obtain", "Cancel" }
    local room = player.room
    if #room:canMoveCardInBoard() > 0 then
      table.insert(choices, 1, "rangjie_move")
    end
    local choice = room:askToChoice(player, { choices = choices, skill_name = skillName })
    if choice == "Cancel" then
      return false
    end

    if choice == "rangjie_obtain" then
      event:setCostData(self, room:askToChoice(player, { choices = { "basic", "trick", "equip" }, skill_name = skillName }))
    else
      local targets = room:askToChooseToMoveCardInBoard(player, { prompt = "#rangjie-move", skill_name = skillName })
      if #targets == 0 then
        return false
      end
      event:setCostData(self, targets)
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = rangjie.name
    local room = player.room
    local costData = event:getCostData(self)
    if type(costData) == "string" then
      for _, pile in ipairs({ "drawPile", "discardPile" }) do
        local cardIds = room:getCardsFromPileByRule(".|.|.|.|.|" .. costData, 1, pile)
        if #cardIds > 0 then
          room:obtainCard(player, cardIds[1], false, fk.ReasonPrey, player, skillName)
          break
        end
      end
    else
      local targets = costData
      room:askToMoveCardInBoard(player, { target_one = targets[1], target_two = targets[2], skill_name = skillName })
    end
    player:drawCards(1, skillName)
  end,
})

return rangjie
