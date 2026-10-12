local jueyong = fk.CreateSkill {
  name = "jueyong",
  derived_piles = "jueyong_desperation",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jueyong"] = "绝勇",
  [":jueyong"] = "锁定技，当你成为一张非因〖绝勇〗使用的、非转化且非虚拟的牌（【桃】和【酒】除外）指定的目标时，若你是此牌的唯一目标，"..
  "且此时“绝”的数量小于你的体力值，你取消之。然后将此牌置于你的武将牌上，称为“绝”。结束阶段，若你有“绝”，则按照置入顺序从前到后依次结算“绝”，"..
  "令其原使用者对你使用（若此牌使用者不在场，则将此牌置入弃牌堆）。",

  ["jueyong_desperation"] = "绝",
  ["#jueyong-choose"] = "绝勇：选择对%dest使用的%arg的副目标",

  ["$jueyong1"] = "敌围何惧，有死而已！",
  ["$jueyong2"] = "身陷敌阵，战而弥勇！",
}

jueyong:addEffect(fk.TargetConfirming, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(jueyong.name) and
      player == target and
      data.card.trueName ~= "peach" and
      data.card.trueName ~= "analeptic" and
      not (data.extra_data and
      data.extra_data.useByJueyong) and
      not data.card:isVirtual() and
      --朱雀羽扇可以发动
      Fk:getCardById(data.card.id, true).trueName == data.card.trueName and
      data:isOnlyTarget(player) and
      not data.cancelled and
      #player:getPile("jueyong_desperation") < player.hp
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = jueyong.name
    local room = player.room
    data:cancelCurrentTarget()
    if room:getCardArea(data.card) ~= Card.Processing then
      return false
    end

    player:addToPile("jueyong_desperation", data.card, true, skillName)
    if table.contains(player:getPile("jueyong_desperation"), data.card.id) then
      room:addTableMark(player, skillName, { data.card.id, data.from.id })
    end
  end,
})

jueyong:addEffect(fk.EventPhaseStart, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(jueyong.name) and
      player == target and
      player.phase == Player.Finish and
      #player:getPile("jueyong_desperation") > 0
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = jueyong.name
    local room = player.room
    local mark = player:getTableMark(skillName)

    while #player:getPile("jueyong_desperation") > 0 do
      local id = player:getPile("jueyong_desperation")[1]
      local jy_remove = true
      local card = Fk:getCardById(id)

      local pid
      for _, jy_record in ipairs(mark) do
        if #jy_record == 2 and jy_record[1] == id then
          pid = jy_record[2]
          break
        end
      end
      if pid ~= nil then
        local from = room:getPlayerById(pid)
        if from and from:isAlive() then
          if
            not from:prohibitUse(card) and not from:isProhibited(player, card)
            and card.skill:modTargetFilter(from, player, {}, card, {bypass_distances = true})
          then
            local tos = { player }
            if card.skill:getMinTargetNum(from) == 2 then
              local targets = table.filter(room.alive_players, function (p)
                return p ~= player and card.skill:targetFilter(from, p, { player }, {}, card)
              end)
              if #targets > 0 then
                local to_slash = room:askToChoosePlayers(
                  from,
                  {
                    targets = targets,
                    min_num = 1,
                    max_num = 1,
                    prompt = "#jueyong-choose::" .. player.id .. ":" .. card:toLogString(),
                    skill_name = skillName,
                    cancelable = false,
                  }
                )
                if #to_slash > 0 then
                  table.insertTable(tos, to_slash)
                end
              end
            end

            if #tos >= card.skill:getMinTargetNum(from) then
              jy_remove = false
              room:useCard({
                from = from,
                tos = tos,
                card = card,
                extra_data = { useByJueyong = true },
                extraUse = true,
              })
            end
          end
        end
      end
      if jy_remove then
        room:moveCards({
          from = player,
          ids = { id },
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonPutIntoDiscardPile,
          skillName = skillName,
        })
      end
    end
  end,
})

jueyong:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return type(player:getMark(jueyong.name)) == "table"
  end,
  on_refresh = function(self, event, target, player, data)
    ---@type string
    local skillName = jueyong.name
    local room = player.room
    local pile = player:getPile("jueyong_desperation")
    if #pile == 0 then
      room:setPlayerMark(player, skillName, 0)
      return false
    end

    local mark = player:getTableMark(skillName)
    local to_record = {}
    for _, jy_record in ipairs(mark) do
      if #jy_record == 2 and table.contains(pile, jy_record[1]) then
        table.insert(to_record, jy_record)
      end
    end

    if #mark > #to_record then
      room:setPlayerMark(player, skillName, to_record)
    end
  end,
})

return jueyong
