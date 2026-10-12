
local huaren = fk.CreateSkill {
  name = "huaren",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["huaren"] = "化刃",
  [":huaren"] = "限定技，准备阶段，你可以将场上或你的一张武器牌永久移出游戏，摸等同于其攻击范围数量的牌，视为拥有其技能。",

  ["#huaren-invoke"] = "化刃：你可以移除一张武器牌，摸其攻击范围张牌并视为拥有其技能",

  ["$huaren1"] = "从今往后，我便是刀，刀便是我。",
  ["$huaren2"] = "无刀——亦无处不是刀！",
}

huaren:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(huaren.name) and player.phase == Player.Start and
      player:usedSkillTimes(huaren.name, Player.HistoryGame) == 0 then
      for _, id in ipairs(player:getCardIds("h")) do
        if Fk:getCardById(id).sub_type == Card.SubtypeWeapon then
          return true
        end
      end
      for _, p in ipairs(player.room.alive_players) do
        for _, id in ipairs(p:getCardIds("e")) do
          if Fk:getCardById(id).sub_type == Card.SubtypeWeapon then
            return true
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card_data = {}
    local cards = table.filter(player:getCardIds("he"), function (id)
      return Fk:getCardById(id).sub_type == Card.SubtypeWeapon
    end)
    if #cards > 0 then
      table.insert(card_data, { player:toLogString(), cards })
    end
    for _, p in ipairs(room:getOtherPlayers(player)) do
      cards = table.filter(p:getCardIds("e"), function (id)
        return Fk:getCardById(id).sub_type == Card.SubtypeWeapon
      end)
      if #cards > 0 then
        table.insert(card_data, { p:toLogString(), cards })
      end
    end
    local card = room:askToChooseCards(player, {
      target = player,
      min = 1,
      max = 1,
      flag = { card_data = card_data },
      skill_name = huaren.name,
      prompt = "#huaren-invoke",
      cancelable = true,
    })
    if #card > 0 then
      event:setCostData(self, { cards = card })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = event:getCostData(self).cards[1]
    local card = Fk:getCardById(id)  ---@cast card Weapon
    local skills = {}
    if id == player:getMark("shenyu") then
      room:setPlayerMark(player, "shenyu", 0)
    end
    if card:getMark("blood_blade") ~= 0 then
      table.insert(skills, card:getMark("blood_blade"))
    end
    local n = card.attack_range or 0
    if card.equip_skill then
      table.insertIfNeed(skills, card.equip_skill.name)
    end
    room:moveCardTo(id, Card.Void, nil, fk.ReasonJustMove, huaren.name, nil, true, player)
    if not player.dead and n > 0 then
      player:drawCards(n, huaren.name)
    end
    if not player.dead and #skills > 0 then
      room:handleAddLoseSkills(player, skills)
    end
  end,
})

return huaren
