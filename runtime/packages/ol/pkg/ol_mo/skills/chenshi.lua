local chenshi = fk.CreateSkill{
  name = "chenshiz",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["chenshiz"] = "瞋视",
  [":chenshiz"] = "锁定技，若其他角色的勾玉颜色与你：<br>"..
    "不同，你使用黑色【杀】能额外指定其为目标；<br>相同，你对其，或其对你使用的黑色【杀】改为【决斗】。<br>"..
    "你因【杀】和【决斗】首次造成了或受到了至少3点伤害后，你回复1点体力，"..
    "<a href=':zhuohun_update'>修改〖灼魂〗</a>并<a href='#RuMoDesc'><font color='red'>入魔</font></a>。",

  ["#chenshiz-choose"] = "瞋视：你可以为此 %arg 额外指定任意个勾玉颜色与你不同的角色为目标",
  ["@chenshiz"] = "瞋视",

  ["$chenshiz1"] = "来来，与我练练身手！",
  ["$chenshiz2"] = "阻我复仇，那便一起受死！",
  ["$chenshiz3"] = "复仇之怒，为蛇矛淬火！",
}

---@param p ServerPlayer
---@return "green" | "yellow" | "red"
local function getHpColor(p)
  local r = p.hp * 3
  return r > 2 * p.maxHp and "green" or r > p.maxHp and "yellow" or "red"
end

chenshi:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  audio_index = 2,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(chenshi.name) and
      data.card.trueName == "slash" and data.card.color == Card.Black then
      local color = getHpColor(player)
      return table.find(data:getExtraTargets({ bypass_distances = true }), function(p)
        return color ~= getHpColor(p)
      end) ~= nil
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local color = getHpColor(player)
    local tos = table.filter(data:getExtraTargets({ bypass_distances = true }), function(p)
      return color ~= getHpColor(p)
    end)
    if #tos > 0 then
      tos = room:askToChoosePlayers(player, {
        targets = tos,
        min_num = 1,
        max_num = #tos,
        prompt = "#chenshiz-choose:::"..data.card:toLogString(),
        skill_name = chenshi.name,
        cancelable = true,
      })
      if #tos > 0 then
        data:addTarget(tos)
        room:sendLog{
          type = "#AddTargetsBySkill",
          from = player.id,
          to = table.map(tos, Util.IdMapper),
          arg = chenshi.name,
          arg2 = data.card:toLogString(),
        }
      end
    end
  end,
})

chenshi:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  priority = 5,
  audio_index = 1,
  can_trigger = function(self, event, target, player, data)
    if data.firstTarget and player:hasSkill(chenshi.name) and
      data.card.trueName == "slash" and data.card.color == Card.Black then
      local color = getHpColor(player)
      return (player == data.from and table.find(data.use.tos, function(p)
        return color == getHpColor(p)
      end) ~= nil) or (color == getHpColor(data.from) and table.contains(data.use.tos, player))
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    --必须实体牌在处理区时才能转化【决斗】，不进行合法性检测
    local cardlist = Card:getIdList(data.card)
    if #cardlist == 0 or table.every(cardlist, function(id)
      return room:getCardArea(id) == Card.Processing
    end) then
      if not data.use.extraUse then
        data.from:addCardUseHistory(data.card.trueName, -1)
        data.use.extraUse = true
      end
      local card = Fk:cloneCard("duel")
      card:addSubcards(cardlist)
      card.skillName = chenshi.name
      room:useCard{
        from = data.from,
        tos = table.simpleClone(data.use.tos),
        card = card,
      }
      local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if use_event then
        use_event:shutdown()
      end
    end
  end,
})

chenshi:addEffect(fk.Damage, {
  audio_index = 3,
  anim_type = "big",
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card and table.contains({ "slash", "duel" }, data.card.trueName) and
      player:hasSkill(chenshi.name) and not player:hasSkill("#rumo", true)
  end,
  on_cost = function(self, event, target, player, data)
    local mark = player:getMark("@chenshiz")
    local x = (type(mark) == "table" and mark[2] or 0) + data.damage
    if x < 3 then
      event:setCostData(self, { mute = true })
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("@chenshiz")
    if type(mark) ~= "table" then
      mark = { 0, 0 }
    end
    local x = mark[2] + data.damage
    if x < 3 then
      room:setPlayerMark(player, "@chenshiz", { mark[1], x })
    else
      room:setPlayerMark(player, "@chenshiz", 0)
      room:handleAddLoseSkills(player, "#rumo", nil, false, true)
      if player:hasSkill("zhuohun", true) then
        room:addPlayerMark(player, "zhuohun_update", 1)
      end
      if player:isWounded() then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = chenshi.name
        }
      end
    end
  end,
})

chenshi:addEffect(fk.Damaged, {
  audio_index = 3,
  anim_type = "big",
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card and table.contains({ "slash", "duel" }, data.card.trueName) and
      player:hasSkill(chenshi.name) and not player:hasSkill("#rumo", true)
  end,
  on_cost = function(self, event, target, player, data)
    local mark = player:getMark("@chenshiz")
    local x = (type(mark) == "table" and mark[1] or 0) + data.damage
    if x < 3 then
      event:setCostData(self, { mute = true })
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("@chenshiz")
    if type(mark) ~= "table" then
      mark = { 0, 0 }
    end
    local x = mark[1] + data.damage
    if x < 3 then
      room:setPlayerMark(player, "@chenshiz", { x, mark[2] })
    else
      room:setPlayerMark(player, "@chenshiz", 0)
      room:handleAddLoseSkills(player, "#rumo", nil, false, true)
      if player:hasSkill("zhuohun", true) then
        room:addPlayerMark(player, "zhuohun_update", 1)
      end
      if player:isWounded() then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = chenshi.name
        }
      end
    end
  end,
})

return chenshi
