local zhuohun = fk.CreateSkill{
  name = "zhuohun",
  tags = { Skill.Compulsory },
  dynamic_desc = function (self, player, lang)
    if player:getMark("zhuohun_update") > 0 then
      return "zhuohun_update"
    else
      return "zhuohun"
    end
  end,
}

Fk:loadTranslationTable {
  ["zhuohun"] = "灼魂",
  [":zhuohun"] = "锁定技，你的回合内：你的【闪】均视为【杀】；一名角色的勾玉首次变为一个颜色后，你摸一张牌。",

  [":zhuohun_update"] = "锁定技，你的回合内：你的【闪】均视为【杀】；"..
    "一名角色的勾玉首次变为一个颜色后，你将手牌摸至体力上限，并执行对应效果：<br>"..
    "绿色，其本回合摸牌均改为从牌堆中获得等量张【杀】；<br>黄色，其本回合非锁定技失效；<br>"..
    "红色，若没有角色处于濒死状态，其失去所有体力。",

  ["@zhuohun-turn"] = "灼魂",
  ["zhuohun_green"] = "绿",
  ["zhuohun_yellow"] = "黄",

  ["$zhuohun1"] = "炼狱灼魂虽痛，不及丧兄之痛！",
  ["$zhuohun2"] = "前方游魂，可曾见过红面长髯之人？",
  ["$zhuohun3"] = "既已身堕在此，再无退路！",
  ["$zhuohun4"] = "无论往哪看，眼里只剩下肃杀。",
  ["$zhuohun5"] = "逃得出地狱，逃不出困锁！",
  ["$zhuohun6"] = "纵是永堕地狱，此恨难忘难解！",
}

zhuohun:addEffect("filter", {
  audio_index = 3,
  anim_type = "offensive",
  card_filter = function(self, to_select, player)
    return player:hasSkill(zhuohun.name) and Fk:currentRoom():getCurrent() == player and
      to_select.trueName == "jink" and table.contains(player:getCardIds("h"), to_select.id)
  end,
  view_as = function(self, player, card)
    return Fk:cloneCard("slash", card.suit, card.number)
  end,
})

---@return "green" | "yellow" | "red"
local function getHpColor(p)
  local r = p.hp * 3
  return r > 2 * p.maxHp and "green" or r > p.maxHp and "yellow" or "red"
end

---@type TrigSkelSpec<HpChangedTrigFunc>
local spec = {
  on_cost = function(self, event, target, player, data)
    local color = getHpColor(target)
    local dat = {
      tos = { target },
      extra_data = color,
    }
    if player:getMark("zhuohun_update") == 0 then
      if target == player then
        dat.audio_index = 1
      else
        dat.audio_index = 2
      end
    else
      if color == "green" then
        dat.anim_type = "control"
        dat.audio_index = 4
      elseif color == "yellow" then
        dat.anim_type = "control"
        dat.audio_index = 5
      else
        dat.anim_type = "offensive"
        dat.audio_index = 6
      end
    end
    event:setCostData(self, dat)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local skillName = zhuohun.name
    local room = player.room
    local color = event:getCostData(self).extra_data
    local mark = player:getTableMark("zhuohun-turn")
    mark[tostring(target.id)] = mark[tostring(target.id)] or {}
    table.insert(mark[tostring(target.id)], color)
    room:setPlayerMark(player, "zhuohun-turn", mark)
    if player:getMark("zhuohun_update") == 0 then
      player:drawCards(1, skillName)
    else
      local num = player.maxHp - player:getHandcardNum()
      if num > 0 then
        player:drawCards(num, skillName)
      end
      if target.dead then return end
      if color == "green" then
        room:addTableMarkIfNeed(target, "@zhuohun-turn", "zhuohun_green")
      elseif color == "yellow" then
        room:addTableMarkIfNeed(target, "@zhuohun-turn", "zhuohun_yellow")
        room:addPlayerMark(target, MarkEnum.UncompulsoryInvalidity .. "-turn")
      elseif color == "red" and table.every(room.alive_players, function(p)
        return not p.dying
      end) and target.hp > 0 then
        room:loseHp(target, target.hp, skillName, player)
      end
    end
  end,
}

zhuohun:addEffect(fk.HpChanged, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhuohun.name) and player.room:getCurrent() == player and data.num < 0 then
      local color = getHpColor(target)
      --按原体力值计算颜色
      local r = (target.hp - data.num) * 3
      if color ~= (r > 2 * target.maxHp and "green" or r > target.maxHp and "yellow" or "red") then
        local mark = player:getTableMark("zhuohun-turn")
        return mark[tostring(target.id)] == nil or not table.contains(mark[tostring(target.id)], color)
      end
    end
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

zhuohun:addEffect(fk.HpRecover, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhuohun.name) and player.room:getCurrent() == player then
      local color = getHpColor(target)
      --按原体力值计算颜色
      local r = (target.hp - data.num) * 3
      if color ~= (r > 2 * target.maxHp and "green" or r > target.maxHp and "yellow" or "red") then
        local mark = player:getTableMark("zhuohun-turn")
        return mark[tostring(target.id)] == nil or not table.contains(mark[tostring(target.id)], color)
      end
    end
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

zhuohun:addEffect(fk.MaxHpChanged, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhuohun.name) and player.room:getCurrent() == player then
      local color = getHpColor(target)
      --按原体力值计算颜色
      --FIXME: 体力上限的变化可能伴随体力值溢出调整，这里获取不到体力值的变化量，导致计算可能会有偏差
      local r = target.hp * 3
      local m = target.maxHp - data.num
      if color ~= (r > 2 * m and "green" or r > m and "yellow" or "red") then
        local mark = player:getTableMark("zhuohun-turn")
        return mark[tostring(target.id)] == nil or not table.contains(mark[tostring(target.id)], color)
      end
    end
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

--摸牌时改为摸杀，效果待定
zhuohun:addEffect(fk.BeforeDrawCard, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.num > 0 and
      table.contains(player:getTableMark("@zhuohun-turn"), "zhuohun_green")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = data.num
    data.num = 0
    local cards = room:getCardsFromPileByRule("slash", x)
    if #cards > 0 then
      room:obtainCard(player, cards, false, fk.ReasonJustMove, player, zhuohun.name)
    end
  end,
})

return zhuohun
