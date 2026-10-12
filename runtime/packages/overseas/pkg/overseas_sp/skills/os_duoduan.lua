local osDuoduan = fk.CreateSkill {
  name = "os__duoduan"
}

Fk:loadTranslationTable{
  ["os__duoduan"] = "度断",
  [":os__duoduan"] = "每回合限一次，当你成为【杀】的目标后，你可重铸一张牌，" ..
  "然后你选择一项令此【杀】的使用者执行：1.摸两张牌令此【杀】无效；2.弃置一张牌令此【杀】不可被响应。",

  ["#os__duoduan-ask"] = "度断：你可重铸一张牌",
  ["#os__duoduan-choose"] = "度断：请选择一项令 %dest 执行",
  ["os__duoduan_draw"] = "其摸两张牌令此杀无效",
  ["os__duoduan_discard"] = "其弃置一张牌令此杀不可被响应",

  ["$os__duoduan1"] = "北伐之事，丞相亦听我定夺。",
  ["$os__duoduan2"] = "筹定规画，片刻既定！",
}

osDuoduan:addEffect(fk.TargetConfirmed, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(osDuoduan.name) and
      data.card.trueName == "slash" and
      not player:isNude() and
      player:usedSkillTimes(osDuoduan.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local cids = player.room:askToCards(
    player,
      {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = osDuoduan.name,
        prompt = "#os__duoduan-ask",
      }
    )
    if #cids > 0 then
      event:setCostData(self, cids)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osDuoduan.name
    local room = player.room
    room:recastCard(event:getCostData(self), player, skillName)
    local from = data.from
    if not from:isAlive() then
      return false
    end

    local choiceList = { "os__duoduan_draw" }
    if not from:isNude() then
      table.insert(choiceList, "os__duoduan_discard")
    end
    local chioce = room:askToChoice(
      player,
      {
        choices = choiceList,
        skill_name = skillName,
        prompt = "#os__duoduan-choose::" .. from.id,
        all_choices = { "os__duoduan_draw", "os__duoduan_discard" },
      }
    )

    if chioce == "os__duoduan_draw" then
      from:drawCards(2, skillName)
      data.use.nullifiedTargets = data.use.nullifiedTargets or {}
      table.forEach(room.players, function(p)
        table.insertIfNeed(data.use.nullifiedTargets, p)
      end)
    else
      if
        #room:askToDiscard(
          from,
          {
            min_num = 1,
            max_num = 1,
            include_equip = true,
            skill_name = skillName,
            cancelable = false,
          }
        ) == 0
      then
        return false
      end

      data.use.disresponsiveList = data.use.disresponsiveList or {}
      table.forEach(room.players, function(p)
        table.insertIfNeed(data.use.disresponsiveList, p)
      end)
    end
  end,
})

return osDuoduan
