local lingren = fk.CreateSkill{
  name = "lingren",
  related_skills = { "ex__jianxiong", "xingshang" },
}

Fk:loadTranslationTable{
  ["lingren"] = "凌人",
  [":lingren"] = "每回合限一次，当你使用【杀】或伤害锦囊牌时，你可以猜测其中一个目标的手牌中是否有基本牌、锦囊牌或装备牌，"..
    "若至少猜对：1项，本回合你下次对其伤害+1；2项，此牌不计入次数，你摸两张牌；3项，你获得〖奸雄〗〖行殇〗直到你下回合开始。",

  ["#lingren-choose"] = "凌人：猜测其中一名目标角色的手牌中是否有基本牌、锦囊牌或装备牌",
  ["#lingren-invoke"] = "凌人：是否对 %dest 发动，猜测其手牌中是否有基本牌、锦囊牌或装备牌",
  ["#lingren-choice"] = "凌人：猜测 %dest 有哪些类型的手牌（可多选）",
  ["lingren_basic"] = "有基本牌",
  ["lingren_trick"] = "有锦囊牌",
  ["lingren_equip"] = "有装备牌",
  ["#lingren_result"] = "%from 猜对了 %arg 项",

  ["#lingren-box-selected"] = "已选：",
  ["#lingren-box-basic"] = "基本",
  ["#lingren-box-trick"] = "锦囊",
  ["#lingren-box-equip"] = "装备",
  ["#lingren-box-basic-short"] = "基",
  ["#lingren-box-trick-short"] = "锦",
  ["#lingren-box-equip-short"] = "装",

  ["$lingren1"] = "敌势已缓，休要走了老贼！",
  ["$lingren2"] = "精兵如炬，困龙难飞！",
  ["$ex__jianxiong_caoying"] = "且收此弩箭，不日奉还。",
  ["$xingshang_caoying"] = "此刀枪军械，尽归我有。",
}

lingren:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return data.from == player and player:hasSkill(lingren.name) and data.card.is_damage_card and
      player:usedSkillTimes(lingren.name, Player.HistoryTurn) == 0 and
      table.find(data.tos, function(p)
        return not p.dead
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(data.tos, function(p)
      return not p.dead
    end)
    if #targets == 1 then
      if room:askToSkillInvoke(player, {
        skill_name = lingren.name,
        prompt = "#lingren-invoke::" .. targets[1].id,
      }) then
        event:setCostData(self, { tos = targets })
        return true
      end
    else
      targets = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#lingren-choose",
        skill_name = lingren.name,
        cancelable = true,
      })
      if #targets > 0 then
        event:setCostData(self, { tos = targets })
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    -- 随机获取三类牌各一张牌名，用作 QML 背景图（按房间开启的卡牌包筛选）
    local basicNames = Fk:getAllCardNames("b")
    local trickNames = Fk:getAllCardNames("td")
    local equipNames = Fk:getAllCardNames("e")
    local basicPic = #basicNames > 0 and table.random(basicNames) or "slash"
    local trickPic = #trickNames > 0 and table.random(trickNames) or "duel"
    local equipPic = #equipNames > 0 and table.random(equipNames) or "crossbow"
    local result = room:askToCustomDialog(player, {
      skill_name = lingren.name,
      component = {
        url = "packages/ol/qml/LingrenBox.qml",
        prop = {
          prompt = "#lingren-choice::"..to.id,
          basicPic = basicPic,
          trickPic = trickPic,
          equipPic = equipPic,
        },
      },
    })
    local yes = {}
    if type(result) == "table" then
      for _, t in ipairs(result) do
        if t == "basic" or t == "trick" or t == "equip" then
          table.insertIfNeed(yes, "lingren_" .. t)
        end
      end
    end
    local choices = {"lingren_basic", "lingren_trick", "lingren_equip"}
    for _, value in ipairs(yes) do
      table.removeOne(choices, value)
    end
    local right = 0
    for _, id in ipairs(to:getCardIds("h")) do
      local str = "lingren_"..Fk:getCardById(id):getTypeString()
      if table.contains(yes, str) then
        right = right + 1
        table.removeOne(yes, str)
      else
        table.removeOne(choices, str)
      end
    end
    right = right + #choices
    room:sendLog{
      type = "#lingren_result",
      from = player.id,
      arg = tostring(right),
      toast = true,
    }
    if right > 0 then
      room:setPlayerMark(player, "lingren_damage-turn", to)
    end
    if right > 1 then
      if not data.extraUse then
        data.extraUse = true
        data.from:addCardUseHistory(data.card.trueName, -1)
      end
      player:drawCards(2, lingren.name)
      if player.dead then return end
    end
    if right > 2 then
      local skills = {}
      if not player:hasSkill("ex__jianxiong", true) then
        table.insert(skills, "ex__jianxiong")
      end
      if not player:hasSkill("xingshang", true) then
        table.insert(skills, "xingshang")
      end
      if #skills > 0 then
        room:setPlayerMark(player, lingren.name, skills)
        room:handleAddLoseSkills(player, table.concat(skills, "|"))
      end
    end
  end,
})

lingren:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player == data.from and player:hasSkill(lingren.name) and player:getMark("lingren_damage-turn") == data.to
  end,
  on_cost = function(self, event, target, player, data)
    event:setCostData(self, { tos = { data.to } })
    return true
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "lingren_damage-turn", 0)
    data:changeDamage(1)
  end,
})

lingren:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark(lingren.name) ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local skills = player:getMark(lingren.name)
    room:setPlayerMark(player, lingren.name, 0)
    room:handleAddLoseSkills(player, "-"..table.concat(skills, "|-"))
  end,
})

return lingren
