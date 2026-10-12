local zhenwei = fk.CreateSkill {
  name = "os__zhenweiz",
}

Fk:loadTranslationTable{
  ["os__zhenweiz"] = "镇围",
  [":os__zhenweiz"] = "出牌阶段限一次，你可以令一名其他角色与你同时选择是否弃置至少一张牌。然后你可执行至多X项" ..
  "（X为你弃置牌不小于其的条件数：1.牌数；2.花色数；3.类别数）：<br />" ..
  "1.获得1点护甲；2.摸四张牌；3.对其造成1点伤害。",

  ["#os__zhenweiz-active"] = "镇围：你可令一名其他角色与你同时弃牌",
  ["#os__zhenweiz-discard"] = "镇围：你可弃置至少一张牌",
  ["os__zhenweiz_shield"] = "获得1点护甲",
  ["os__zhenweiz_draw"] = "摸四张牌",
  ["os__zhenweiz_damage"] = "对%dest造成1点伤害",
  ["#os__zhenweiz-choose"] = "镇围：你可选择至多%arg项执行",
  ["@os__zhenweiz_effect-noclear"] = "镇围",
  ["os__zhenweiz_effect_shield"] = "护甲",
  ["os__zhenweiz_effect_dmg"] = "造成伤害",
  ["os__zhenweiz_effect_draw"] = "摸牌",

  ["$os__zhenweiz1"] = "谅此等之敌，不过乌合之众！",
  ["$os__zhenweiz2"] = "敌军兵疲马乏，正是出击之时。",
}

zhenwei:addEffect("active", {
  prompt = "#os__zhenweiz-active",
  card_num = 0,
  target_num = 1,
  can_use = function (self, player)
    return player:usedSkillTimes(zhenwei.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = zhenwei.name
    local from = effect.from
    local to = effect.tos[1]

    local targets = { from, to }
    table.forEach(room.alive_players, function(p)
      if table.contains(p:getTableMark("@[list]os__heyuan_owners-noclear"), from) then
        table.insertIfNeed(targets, p)
      end
    end)

    local result = room:askToJointCards(
      from,
      {
        min_num = 1,
        max_num = 999,
        players = targets,
        include_equip = true,
        will_throw = true,
        skill_name = skillName,
        prompt = "#os__zhenweiz-discard",
      }
    )

    local moveList, numRecord, suitRecord, typeRecord = {}, {}, {}, {}
    for p, ids in pairs(result) do
      if #ids > 0 then
        table.insert(moveList, {
          ids = ids,
          from = p,
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonDiscard,
          skillName = skillName,
          proposer = p,
        })
      end

      if p == from then
        room:setPlayerMark(from, "os__zhenweiz_discard-noclear", #ids == 0 and -1 or #ids)
      end

      local recorder = p == to and to or from -- 合援角色记为 from
      numRecord[recorder] = numRecord[recorder] or 0
      numRecord[recorder] = numRecord[recorder] + #ids
      suitRecord[recorder] = suitRecord[recorder] or {}
      typeRecord[recorder] = typeRecord[recorder] or {}
      table.forEach(ids, function(id)
        local card = Fk:getCardById(id)
        local suit = card.suit
        if suit ~= Card.NoSuit then
          table.insertIfNeed(suitRecord[recorder], suit)
        end
        table.insertIfNeed(typeRecord[recorder], card.type)
      end)
    end

    if #moveList > 0 then
      room:moveCards(table.unpack(moveList))
    end

    local maxNum = 0
    if numRecord[from] >= numRecord[to] then
      maxNum = maxNum + 1
    end

    if #suitRecord[from] >= #suitRecord[to] then
      maxNum = maxNum + 1
    end

    if #typeRecord[from] >= #typeRecord[to] then
      maxNum = maxNum + 1
    end

    if not (maxNum > 0 and from:isAlive()) then
      return false
    end

    local choices = { "os__zhenweiz_shield", "os__zhenweiz_draw", "os__zhenweiz_damage::" .. to.id }
    if not to:isAlive() then
      table.remove(choices)
    end

    local chosen = room:askToChoices(
      from,
      {
        min_num = 1,
        max_num = maxNum,
        choices = choices,
        all_choices = { "os__zhenweiz_shield", "os__zhenweiz_draw", "os__zhenweiz_damage::" .. to.id },
        skill_name = skillName,
        prompt = "#os__zhenweiz-choose:::" .. maxNum,
      }
    )

    if table.contains(chosen, "os__zhenweiz_shield") then
      room:setPlayerMark(from, "@os__zhenweiz_effect-noclear", "os__zhenweiz_effect_shield")
      room:changeShield(from, 1)
    end

    if table.contains(chosen, "os__zhenweiz_draw") and from:isAlive() then
      room:setPlayerMark(from, "@os__zhenweiz_effect-noclear", "os__zhenweiz_effect_draw")
      from:drawCards(4, skillName)
    end

    if table.contains(chosen, "os__zhenweiz_damage::" .. to.id) then
      room:doIndicate(from, { to })
      room:setPlayerMark(from, "@os__zhenweiz_effect-noclear", "os__zhenweiz_effect_dmg")

      room:damage{
        from = from,
        to = to,
        damage = 1,
        skillName = skillName,
      }
    end

  end,
})

return zhenwei
