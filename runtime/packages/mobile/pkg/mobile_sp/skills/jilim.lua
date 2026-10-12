local jilim = fk.CreateSkill {
  name = "jilim",
}

Fk:loadTranslationTable{
  ["jilim"] = "积戾",
  [":jilim"] = "其他角色的回合开始时，若其在你的攻击范围内，你可以秘密选择0~2中一个你本轮未选择过的数字。" ..
  "若如此做，本回合的结束阶段，若其本回合使用牌指定你为目标的次数：小于X，你摸4-X张牌；等于X，你交给其X张牌；大于X，" ..
  "你可以视为对其使用一张无距离限制的【杀】（X为你本次选择的数字）。",

  ["#jilim-choice"] = "积戾：秘密选择其中一个数字，根据 %dest 本回合指定你为目标的次数和此数字的关系执行效果",
  ["#jilim-give"] = "积戾：请选择 %arg 张牌交给 %dest",
  ["#jilim-slash"] = "积戾：你可以视为对 %dest 使用一张【杀】",

  ["$jilim1"] = "势利所加，改亲为雠，况非亲亲乎！",
  ["$jilim2"] = "臣委质以来，愆戾山积，臣犹自如，况于君乎！",
  ["$jilim3"] = "陛下思贤若渴，虚心侧席，智者莫不归命。",
  ["$jilim4"] = "臣窃慕陛下圣姿，远来委质，岂为刘备刺客乎！",
  ["$jilim5"] = "臣固未可始终，然实为封欺人太甚！",
  ["$jilim6"] = "沧溟纵容百川，尚有平波之激荡。",
  ["$jilim7"] = "臣但镇疆御土，安有别图？",
  ["$jilim8"] = "臣之心也，陛下素有所知，今何可疑乎？",
  ["$jilim9"] = "臣虽卑鄙，亦知礼义二字。",
}

jilim:addEffect(fk.TurnStart, {
  audio_index = { 1, 2 },
  can_trigger = function(self, event, target, player, data)
    return
      target ~= player and
      player:hasSkill(jilim.name) and
      player:inMyAttackRange(target) and
      #player:getTableMark("jilim_chosen-round-noclear") < 3
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {}
    local allChoices = {}
    for i = 0, 2 do
      if not table.contains(player:getTableMark("jilim_chosen-round-noclear"), i) then
        table.insert(choices, tostring(i))
      end

      table.insert(allChoices, tostring(i))
    end

    if #choices == 0 then
      return false
    end
    table.insert(choices, "Cancel")
    table.insert(allChoices, "Cancel")

    local choice = player.room:askToChoice(
      player,
      {
        choices = choices,
        skill_name = jilim.name,
        prompt = "#jilim-choice::" .. target.id,
        all_choices = allChoices,
      }
    )

    if choice ~= "Cancel" then
      player.room:addTableMarkIfNeed(player, "jilim_chosen-round-noclear", tonumber(choice))
      event:setCostData(self, { tos = { target }, chioce = choice })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local number = event:getCostData(self).chioce
    player.room:setPlayerMark(player, "jilim_record-turn", number)
  end,
})

jilim:addEffect(fk.EventPhaseStart, {
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return
      target.phase == Player.Finish and
      target ~= player and
      player:isAlive() and
      player:getMark("jilim_record-turn") ~= 0
  end,
  on_cost = function(self, event, target, player, data)
    local times = #player.room.logic:getEventsOfScope(GameEvent.UseCard, 3, function (e)
      local use = e.data
      return use.from == target and table.contains(use.tos, player)
    end, Player.HistoryTurn)

    local audioIndex = { 3, 4 }
    local record = tonumber(player:getMark("jilim_record-turn"))
    if times < record then
      audioIndex = { 7, 8, 9 }
    elseif times > record then
      audioIndex = { 5, 6 }
    end

    event:setCostData(self, { audio_index = player.room:tableRandomPick(audioIndex), times = times })
    return true
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = jilim.name
    local room = player.room
    local times = event:getCostData(self).times

    local record = tonumber(player:getMark("jilim_record-turn"))  ---@cast record integer
    if times < record then
      player:drawCards(4 - record, skillName)
    elseif times == record then
      if not (not player:isNude() and record > 0 and target:isAlive()) then
        return false
      end

      local ids = room:askToCards(player, {
        min_num = record,
        max_num = record,
        include_equip = true,
        skill_name = skillName,
        prompt = "#jilim-give::" .. target.id .. ":" .. record,
        cancelable = false,
      })

      room:obtainCard(target, ids, false, fk.ReasonGive, player, skillName)
    else
      local slash = Fk:cloneCard("slash")
      if not (target:isAlive() and player:canUseTo(slash, target, { bypass_distances = true, bypass_times = true })) then
        return false
      end

      if room:askToSkillInvoke(player, { skill_name = jilim.name, prompt = "#jilim-slash::" .. target.id }) then
        room:useCard{
          from = player,
          tos = { target },
          card = slash,
        }
      end
    end
  end,
})

return jilim
