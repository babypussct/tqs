local osZhiqu = fk.CreateSkill {
  name = "os__zhiqu"
}

Fk:loadTranslationTable{
  ["os__zhiqu"] = "直取",
  [":os__zhiqu"] = "结束阶段，你可选择一名其他角色并依次亮出牌堆顶X张牌，对其使用其中的【杀】。（X为你至其距离1以内的角色数）" ..
  "若<a href='os__wrestle'>搏击</a>：改为使用其中的【杀】和锦囊牌，这些牌只能指定你或其为目标。",

  ["#os__zhiqu-ask"] = "你可对一名其他角色发动“直取”，依次亮出牌堆顶的 %arg 张牌，使用其中的一些牌",
  ["#os__zhiqu-target"] = "直取：选择你使用%arg的目标",

  ["$os__zhiqu1"] = "八百之众，哼，须臾可灭！",
  ["$os__zhiqu2"] = "此战首功，当由我取之！",
}

osZhiqu:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(osZhiqu.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local num = #table.filter(room.alive_players, function(p) return player:distanceTo(p) <= 1 end)
    local tos = room:askToChoosePlayers(
      player,
      {
        targets = room:getOtherPlayers(player, false),
        min_num = 1,
        max_num = 1,
        prompt = "#os__zhiqu-ask:::" .. num,
        skill_name = osZhiqu.name,
      }
    )
    if #tos > 0 then
      event:setCostData(self, tos[1])
      return true
    end
  end,
  on_use = function(self, event, target, player)
    ---@type string
    local skillName = osZhiqu.name
    local room = player.room
    local num = #table.filter(room.alive_players, function(p) return player:distanceTo(p) <= 1 end)
    local to = event:getCostData(self)
    local wrestle = player:inMyAttackRange(to) and to:inMyAttackRange(player)

    for i = 1, num, 1 do
      local ids = room:getNCards(1)
      room:turnOverCardsFromDrawPile(player, ids, skillName)
      local card = Fk:getCardById(ids[1])
      if
        (card.trueName == "slash" or card.name == "n_brick") and
        player:canUseTo(card, to, { bypass_distances = true, bypass_times = true }) and
        to:isAlive()
      then --彩蛋
        room:useCard{
          card = card,
          from = player,
          tos = { to },
          skillName = skillName,
          extraUse = true,
        }
      end
      if wrestle and card.type == Card.TypeTrick and player:canUse(card, { bypass_times = true, bypass_distances = true }) then
        local targets = {}
        local tos, subTos
        for _, p in ipairs({player, to}) do
          if not player:isProhibited(p, card) then
            if card.skill:modTargetFilter(player, p, {}, card, { bypass_times = true, bypass_distances = true }) then
              table.insert(targets, p)
            end
          end
        end
        if #targets > 0 then
          if card.skill:getMinTargetNum(player) == 0 then
            if not card.multiple_targets then
              if table.contains(targets, player) then
                tos = { player }
              end
            else
              tos = targets
            end
          elseif card.skill:getMinTargetNum(player) == 2 then
            if table.contains(targets, to) then
              subTos = { player }
            end
          else
            if #targets == 1 then
              tos = targets
            else
              local temp = room:askToChoosePlayers(
                player,
                {
                  targets = targets,
                  min_num = 1,
                  max_num = #targets,
                  prompt = "#os__zhiqu-target:::" .. card:toLogString(),
                  skill_name = skillName,
                  cancelable = false,
                }
              )
              if #temp > 0 then
                tos = temp
              end
            end
          end
        end

        if tos then
          room:useCard{
            card = card,
            from = player,
            tos = tos,
            skillName = skillName,
            extraUse = true,
            subTos = subTos,
          }
        end
      end
      room:cleanProcessingArea(ids, skillName)
    end
  end,
})

return osZhiqu
