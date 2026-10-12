
local dichou = fk.CreateSkill{
  name = "dichou",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["dichou"] = "涤仇",
  [":dichou"] = "锁定技，其他角色对你使用牌时获得一个“仇”标记。"..
  "你的回合开始时，废除一个装备栏并获得一名角色一张牌，本回合你攻击范围与出【杀】次数增加此牌名字数。"..
  "你对有“仇”的角色使用牌时摸一张牌并移去一个“仇”。"..
  "你的回合结束时，你对任意名有“仇”的角色各造成1点火焰伤害并移去所有“仇”。",

  ["@dichou"] = "仇",
  ["#dichou-abort"] = "涤仇：废除一个装备栏",
  ["#dichou-prey"] = "涤仇：获得一名角色一张牌，本回合你出【杀】次数增加此牌名字数",
  ["#dichou-damage"] = "涤仇：对任意名有“仇”的角色各造成1点火焰伤害！",

  ["$dichou1"] = "",
  ["$dichou2"] = "",
}

dichou:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(dichou.name) then
      if target ~= player then
        return table.contains(data.tos, player) and not target.dead
      else
        return table.find(data.tos, function (p)
          return p:getMark("@dichou") > 0
        end)
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if target ~= player then
      room:addPlayerMark(target, "@dichou", 1)
    else
      for _, p in ipairs(room:getAlivePlayers()) do
        if not player:hasSkill(dichou.name) then return end
        if table.contains(data.tos, p) and p:getMark("@dichou") > 0 then
          room:removePlayerMark(p, "@dichou", 1)
          player:drawCards(1, dichou.name)
        end
      end
    end
  end,
})

dichou:addEffect(fk.TurnStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dichou.name) and
      #player:getAvailableEquipSlots() > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = player.room:askToChoice(player, {
      choices = player:getAvailableEquipSlots(),
      skill_name = dichou.name,
      prompt = "#dichou-abort",
      cancelable = false,
    })
    room:abortPlayerArea(player, choice)
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return not p:isNude()
    end)
    if player.dead or #targets == 0 then return end
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#dichou-prey",
      skill_name = dichou.name,
      cancelable = false,
    })[1]
    local id = room:askToChooseCard(player, {
      target = to,
      flag = "he",
      skill_name = dichou.name,
    })
    local n = Fk:getCardById(id):getNameLength()
    room:addPlayerMark(player, "dichou_range-turn", n)
    room:addPlayerMark(player, MarkEnum.SlashResidue .. "-turn", n)
    room:moveCardTo(id, Card.PlayerHand, player, fk.ReasonPrey, dichou.name, nil, false, player)
  end,
})

dichou:addEffect(fk.TurnEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dichou.name) and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return p:getMark("@dichou") > 0
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return p:getMark("@dichou") > 0
    end)
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = #targets,
      prompt = "#dichou-damage",
      skill_name = dichou.name,
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      for _, p in ipairs(tos) do
        if not p.dead then
          room:damage{
            from = player,
            to = p,
            damage = 1,
            damageType = fk.FireDamage,
            skillName = dichou.name,
          }
        end
      end
    end
    for _, p in ipairs(room.alive_players) do
      room:setPlayerMark(p, "@dichou", 0)
    end
  end,
})

dichou:addEffect("atkrange", {
  correct_func = function(self, from, to)
    return from:getMark("dichou_range-turn")
  end,
})

return dichou
