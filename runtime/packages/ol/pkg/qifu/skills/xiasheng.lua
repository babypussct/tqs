local xiasheng = fk.CreateSkill({
  name = "xiasheng",
  tags = { Skill.Compulsory },
  dynamic_desc = function(self, player, lang)
    if player:getMark("xiasheng") > 0 then
      return "xiasheng_inner"
    end
  end,
})

Fk:loadTranslationTable {
  ["xiasheng"] = "夏晟",
  [":xiasheng"] = "锁定技，若你手牌中：红色牌较多，你使用黑色牌时摸一张牌；黑色牌较多，你使用红色牌可以多指定一个目标。",

  [":xiasheng_inner"] = "锁定技，若你手牌中黑色牌较多，你使用黑色牌时摸一张牌，且可以多指定一个目标。",

  ["#xiasheng-choose"] = "夏晟：你可以为%arg额外指定一个目标",

  ["$xiasheng1"] = "小池消长夏，撷莲一朵劝何郎。",
  ["$xiasheng2"] = "茉莉逢初夏，架上茶蘼未了春。",
}

xiasheng:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(xiasheng.name) then
      local n1, n2 = 0, 0
      for _, id in ipairs(player:getCardIds("h")) do
        if Fk:getCardById(id).color == Card.Red then
          n1 = n1 + 2
        elseif Fk:getCardById(id).color == Card.Black then
          n2 = n2 + 2
        end
      end
      if player:getMark(xiasheng.name) == 0 then
        return n1 > n2 and data.card.color == Card.Black
      else
        return n1 < n2 and data.card.color == Card.Black
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, xiasheng.name)
  end,
})

xiasheng:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(xiasheng.name) and #data:getExtraTargets() > 0 then
      local n1, n2 = 0, 0
      for _, id in ipairs(player:getCardIds("h")) do
        if Fk:getCardById(id).color == Card.Red then
          n1 = n1 + 2
        elseif Fk:getCardById(id).color == Card.Black then
          n2 = n2 + 2
        end
        if n1 < n2 then
          if player:getMark(xiasheng.name) == 0 then
            return data.card.color == Card.Red
          else
            return data.card.color == Card.Black
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = data:getExtraTargets(),
      skill_name = xiasheng.name,
      prompt = "#xiasheng-choose:::" .. data.card:toLogString(),
      cancelable = true,
    })
    if #to > 0 then
      data:addTarget(to[1])
    end
  end,
})

xiasheng:addLoseEffect(function(self, player, is_death)
  player.room:setPlayerMark(player, xiasheng.name, 0)
end)

return xiasheng
