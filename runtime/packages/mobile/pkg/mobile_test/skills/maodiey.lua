local maodie = fk.CreateSkill {
  name = "maodiey",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["maodiey"] = "冒迭",
  [":maodiey"] = "锁定技，当你使用牌结算结束后，若此牌造成过伤害，你本回合使用的下一张伤害牌的牌名字数需大于此牌的牌名字数；" ..
  "每回合限两次，若此牌未造成过伤害，你获得一张目标角色于你在游戏开始时发动“集蜜”后的手牌。",

  ["$maodiey1"] = "哈！朕要闹得天翻地覆！",
  ["$maodiey2"] = "敢抢朕的蜜，朕看你是不想活了！",
  ["$maodiey3"] = "按理来说，汝这个级别还无权对朕哈气！",
  ["$maodiey4"] = "朕未到耄耋之年，又怎会冒迭行事！",
}

maodie:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(maodie.name) and data.damageDealt
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "maodiey_prohibit-turn", Fk:translate(data.card.trueName, "zh_CN"):len())
  end,
})

maodie:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      not data.damageDealt and
      #(data.tos or {}) > 0 and
      player:hasSkill(maodie.name) and
      player:usedEffectTimes(self.name) < 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local toObtain = {}
    for _, to in ipairs(data.tos) do
      local cards = player:getTableMark("jimi_record-noclear")[tostring(to.id)]
      if cards == nil then
        break
      end

      local to_get = {}

      local all_players = room:getAllPlayers()
      if to ~= player then
        table.removeOne(all_players, player)
      end
      local index = table.indexOf(all_players, to)
      local p
      for i = index, #all_players, 1 do
        p = all_players[i]
        for _, playerArea in ipairs({ "h", "e", "j" }) do
          to_get = table.filter(p:getCardIds(playerArea), function(id)
            return table.contains(cards, id)
          end)
          if #to_get > 0 then
            if playerArea ~= "h" or p ~= player then
              table.insert(toObtain, room:tableRandomPick(to_get))
              break
            end
          end
        end
      end
      if index > 1 then
        for i = 1, index - 1, 1 do
          p = all_players[i]
          for _, playerArea in ipairs({ "h", "e", "j" }) do
            to_get = table.filter(p:getCardIds(playerArea), function(id)
              return table.contains(cards, id)
            end)
            if #to_get > 0 then
              if playerArea ~= "h" or p ~= player then
                table.insert(toObtain, room:tableRandomPick(to_get))
                break
              end
            end
          end
        end
      end

      to_get = table.filter(cards, function(id)
        return table.contains(room.discard_pile, id)
      end)
      if #to_get == 0 then
        to_get = table.filter(cards, function(id)
          return table.contains(room.draw_pile, id)
        end)
      end
      if #to_get > 0 then
        table.insert(toObtain, room:tableRandomPick(to_get))
        break
      end

      if to ~= player then
        for _, playerArea in ipairs({ "e", "j" }) do
          to_get = table.filter(player:getCardIds(playerArea), function(id)
            return table.contains(cards, id)
          end)
          if #to_get > 0 then
            table.insert(toObtain, room:tableRandomPick(to_get))
            break
          end
        end
      end

      to_get = table.filter(cards, function(id)
        return table.contains(room.processing_area, id)
      end)
      if #to_get > 0 then
        table.insert(toObtain, room:tableRandomPick(to_get))
        break
      end
    end

    if #toObtain > 0 then
      room:obtainCard(player, room:tableRandomPick(toObtain), false, fk.ReasonPrey, player, maodie.name)
    end
  end,
})

maodie:addEffect(fk.AfterCardUseDeclared, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return
      target == player and
      player:getMark("maodiey_prohibit-turn") > 0 and
      (data.card.is_damage_card or data.card.name == "lightning")
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "maodiey_prohibit-turn", 0)
  end,
})

maodie:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    local num = player:getMark("maodiey_prohibit-turn")
    if num > 0 then
      return
        card and
        (card.is_damage_card or card.name == "lightning") and
        Fk:translate(card.trueName, "zh_CN"):len() <= num
    end
  end,
})

return maodie
