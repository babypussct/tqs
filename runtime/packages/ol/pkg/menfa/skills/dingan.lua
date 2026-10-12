local dingan = fk.CreateSkill{
  name = "dingan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["dingan"] = "定安",
  [":dingan"] = "锁定技，当一个牌名的牌每回合第二次被使用后，若本回合未有角色进入过濒死状态，"..
    "你与一名非目标角色各摸一张牌（每回合每名角色限一次），"..
    "然后你对手牌最多的其他角色造成1点伤害，或令其弃置手牌中最多的同名牌。",

  ["#dingan-choose"] = "定安：选择1名非目标角色与你各摸1张牌",
  ["#dingan-choice"] = "定安：选择一项效果令 %dest 执行",
  ["#dingan-choose2"] = "定安：选择1名角色，令其执行一项效果",
  ["dingan_damage"] = "你对其造成1点伤害",
  ["dingan_discard"] = "弃置其手牌中最多的同名牌",

  ["$dingan1"] = "今人心思动，非天子无以讨不臣。",
  ["$dingan2"] = "现大乱将起，非英杰无以定海内。",
}

dingan:addEffect(fk.CardUseFinished, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(dingan.name) then
      local room = player.room
      local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
      if use_event == nil then
        return false
      end
      local turn_event = use_event:findParent(GameEvent.Turn, true)
      if turn_event == nil then
        return false
      end
      if #room.logic:getEventsOfScope(GameEvent.Dying, 1, Util.TrueFunc, Player.HistoryTurn) > 0 then
        return false
      end
      local start_id = use_event.id
      local end_id = turn_event.id
      local name = data.card.trueName
      return #room.logic:getEventsByRule(GameEvent.UseCard, 2, function(e)
        return e.id < start_id and e.data.card.trueName == name
      end, end_id) == 1
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local used = player:getTableMark("dingan-turn")
    local skillName = dingan.name
    local tos = table.filter(room.alive_players, function(p)
      return not table.contains(used, p) and not table.contains(data.tos, p)
    end)
    if #tos > 1 then
      tos = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = tos,
        skill_name = skillName,
        prompt = "#dingan-choose",
        cancelable = false,
      })
    end
    if #tos > 0 then
      table.insertTable(used, tos)
      room:setPlayerMark(player, "dingan-turn", used)
    end

    player:drawCards(1, skillName)

    if #tos > 0 and not tos[1].dead then
      tos[1]:drawCards(1, skillName)
    end

    if player.dead then return end
    local x = 0
    local y = 0
    local max_tos = {}
    for _, p in ipairs(room.alive_players) do
      if p ~= player and not p.dead then
        y = p:getHandcardNum()
        if y > x then
          max_tos = { p }
          x = y
        elseif y == x then
          table.insert(max_tos, p)
        end
      end
    end
    if #max_tos == 0 then return
    elseif #max_tos > 1 then
      max_tos = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = max_tos,
        skill_name = skillName,
        prompt = "#dingan-choose2",
        cancelable = false,
      })
    end
    local to = max_tos[1]
    local choice = room:askToChoice(player, {
      choices = {"dingan_damage", "dingan_discard"},
      skill_name = skillName,
      prompt = "#dingan-choice::" .. to.id
    })
    if choice == "dingan_damage" then
      room:damage{
        from = player,
        to = to,
        damage = 1,
        skillName = skillName
      }
    else

      -- 假设 Fk:getCardById 是一个高效的、已存在的函数
      -- Card 对象结构为 { id = int, trueName = string }

      local ids = to:getCardIds("h")

      -- 2. 单次遍历输入表，统计 name 出现次数并映射 id
      --    nameData: { [name: string] = { count: number, ids: int[] } }
      local nameData = {}
      local maxCount = 0

      for _, id in ipairs(ids) do
        -- 修正为 Lua 的方法调用语法
        local card = Fk:getCardById(id)
        local name = card.trueName

        -- 获取或初始化该 name 的数据条目
        local nameEntry = nameData[name]
        if not nameEntry then
          nameEntry = { count = 0, ids = {} }
          nameData[name] = nameEntry
        end

        -- 更新计数和 id 列表
        nameEntry.count = nameEntry.count + 1
        table.insert(nameEntry.ids, id)

        -- 实时更新最大计数，避免后续再次遍历查找
        if nameEntry.count > maxCount then
          maxCount = nameEntry.count
        end
      end

      -- 3. 收集所有出现次数为最大值的 name 对应的 id 列表
      local candidateIdLists = {}
      for _, nameEntry in pairs(nameData) do
        if nameEntry.count == maxCount then
          table.insert(candidateIdLists, nameEntry.ids)
        end
      end

      -- 4. 随机选择一个候选列表并返回
      ids = candidateIdLists[math.random(#candidateIdLists)]

      ids = table.filter(ids, function(id)
        return not to:prohibitDiscard(id)
      end)
      if #ids > 0 then
        room:throwCard(ids, skillName, to, to)
      end
    end
  end,
})

return dingan
