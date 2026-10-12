local minshan = fk.CreateSkill {
  name = "minshan",
}

Fk:loadTranslationTable{
  ["minshan"] = "愍善",
  [":minshan"] = "当你受到1点伤害后，可令一名角色从牌堆中获得两张牌（优先获得你所记录的花色）。",

  ["#minshan-choose"] = "愍善：你可以令一名角色随机获得两张牌",

  ["$minshan1"] = "红颜易老，恻隐之心未褪。",
  ["$minshan2"] = "心虽存微妒，见落叶而怆然。",
}

minshan:addEffect(fk.Damaged, {
  trigger_times=function (self, event, target, player, data)
    return data.damage
  end,
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(minshan.name)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = minshan.name,
      prompt = "#minshan-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local cards = {}
    local mark = player:getTableMark("@[suits]yuxian-round")
    if #mark == 0 then
      cards = room:getNCards(2)
    else
      local pile = room.draw_pile
      if #pile < 2 then
        cards = room:getNCards(2)
      else
        local seen = {}    -- 辅助哈希表，记录已出现的元素
        local suits = {}   -- 存储去重后的结果
        for _, value in ipairs(mark) do
          -- 检查元素是否未出现过
          if not seen[value] then
            seen[value] = true  -- 标记为已出现
            table.insert(suits, value)  -- 加入结果table
          end
        end
        local suit = room:tableRandomPick(suits)
        for i = #pile, 1, -1 do
          local id = pile[i]
          if Fk:getCardById(id).suit == suit then
            table.insert(cards, id)
            if #cards > 1 then
              break
            end
            suit = room:tableRandomPick(suits)
          end
        end
        if #cards < 2 then
          cards = room:getNCards(2)
        end
      end
    end
    room:obtainCard(to, cards, false, fk.ReasonJustMove, player, minshan.name)
  end,
})

return minshan
