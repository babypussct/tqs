local rule = fk.CreateSkill {
  name = "#variation&",
}

Fk:loadTranslationTable{
  ["#variation&"] = "应变",
  ["@fujia"] = "<font color='yellow'>富甲</font>",
  ["@kongchao"] = "<font color='yellow'>空巢</font>",
  ["@canqu"] = "<font color='yellow'>残躯</font>",
  ["@zhuzhan"] = "<font color='yellow'>助战</font>",
  ["variation_addtarget"] = "目标+1",
  ["variation_minustarget"] = "目标-1",
  ["variation_disresponsive"] = "不可响应",
  ["variation_draw"] = "摸牌",
  ["variation_damage"] = "伤害+1",
  ["variation_cancel"] = "获得牌",
  ["#variation-zhuzhan"] = "助战：你可以弃置一张%arg，助战%src使用的%arg2可以额外指定一个目标",
  ["#variation_addtarget"] = "为%arg额外指定一个目标",
  ["#variation_minustarget"] = "为%arg减少一个目标",
}

rule:addEffect(fk.GamePrepared, {
  global = true,
  can_refresh = function (self, event, target, player, data)
    return player.seat == 1 and not table.contains(player.room.disabled_packs, "variation_cards")
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    for _, card in ipairs(Fk.packages["variation_cards"].cards) do
      if card.extra_data and card.extra_data.variation then
        room:setCardMark(card, card.extra_data.variation[1], Fk:translate(card.extra_data.variation[2]))
      end
    end
  end,
})

rule:addEffect(fk.AfterCardUseDeclared, {
  global = true,
  priority = 0.001,
  can_refresh = function(self, event, target, player, data)
    return target == player and
      table.find({"@fujia", "@kongchao", "@canqu", "@zhuzhan"}, function(mark)
        return data.card.extra_data and data.card.extra_data.variation and
          data.card.extra_data.variation[1] == mark
      end)
  end,
  on_refresh = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.variation_type = data.extra_data.variation_type or {}
    for _, mark in ipairs({"@fujia", "@kongchao", "@canqu", "@zhuzhan"}) do
      if data.card.extra_data and data.card.extra_data.variation and data.card.extra_data.variation[1] == mark then
        local yes = table.contains(data.extra_data.variation_type, mark)
        if not yes then
          if mark == "@fujia" then
            yes = table.every(player.room:getOtherPlayers(player, false), function(p)
              return player:getHandcardNum() >= p:getHandcardNum()
            end)
          elseif mark == "@kongchao" then
            yes = player:isKongcheng()
          elseif mark == "@canqu" then
            yes = player.hp == 1
          elseif mark == "@zhuzhan" then
            local room = player.room
            local targets = table.filter(room:getOtherPlayers(player, false), function (p)
              return not p:isKongcheng() and not table.contains(data.tos, p)
            end)
            if #targets > 0 then
              local extra_data = {
                num = 1,
                min_num = 1,
                include_equip = false,
                skillName = rule.name,
                pattern = ".|.|.|.|.|"..data.card:getTypeString(),
              }
              local dat = {
                "discard_skill",
                "#variation-zhuzhan:"..player.id.."::"..data.card:getTypeString()..":"..data.card:toLogString(),
                true,
                extra_data,
              }
              local req = Request:new(targets, "AskForUseActiveSkill")
              req.focus_text = "@zhuzhan"
              req.n = 1
              for _, p in ipairs(targets) do req:setData(p, dat) end
              req:ask()
              local winner = req.winners[1]
              if winner then
                local result = req:getResult(winner)
                local ids = result
                if result ~= "" then
                  if result.card then
                    ids = result.card.subcards
                  else
                    ids = result
                  end
                end
                yes = true
                room:throwCard(ids, rule.name, winner, winner)
              end
            end
          end
        end
        if yes then
          table.insertIfNeed(data.extra_data.variation_type, mark)
        end
      end
    end
    data.extra_data.variation_effects = data.extra_data.variation_effects or {}
    for _, mark in ipairs({"@fujia", "@kongchao", "@canqu", "@zhuzhan"}) do
      if data.card.extra_data and data.card.extra_data.variation and data.card.extra_data.variation[1] == mark and
        table.contains(data.extra_data.variation_type, mark) then
        table.insertIfNeed(data.extra_data.variation_effects, data.card.extra_data.variation[2])
      end
    end
  end,
})

rule:addEffect(fk.AfterCardTargetDeclared, {
  global = true,
  priority = 0.001,
  mute = true,
  can_trigger = function (self, event, target, player, data)
    if target == player and data.extra_data and data.extra_data.variation_effects and not player.dead then
      if table.contains(data.extra_data.variation_effects, "variation_minustarget") and #data.tos > 0 then
        return true
      end
      if table.contains(data.extra_data.variation_effects, "variation_addtarget") and #data:getExtraTargets() > 0 then
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if table.contains(data.extra_data.variation_effects, "variation_minustarget") and #data.tos > 0 then
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = data.tos,
        skill_name = rule.name,
        prompt = "#variation_minustarget:::"..data.card:toLogString(),
        cancelable = true,
      })
      if #to > 0 then
        data:removeTarget(to[1])
      end
    end
    if table.contains(data.extra_data.variation_effects, "variation_addtarget") and #data:getExtraTargets() > 0 then
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = data:getExtraTargets(),
        skill_name = rule.name,
        prompt = "#variation_addtarget:::"..data.card:toLogString(),
        cancelable = true,
      })
      if #to > 0 then
        data:addTarget(to[1])
      end
    end
  end,
})

rule:addEffect(fk.CardUsing, {
  global = true,
  priority = 0.001,
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and data.extra_data and data.extra_data.variation_effects and
      #data.extra_data.variation_effects > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if table.contains(data.extra_data.variation_effects, "variation_disresponsive") then
      data.disresponsiveList = table.simpleClone(room.players)
    end
    if table.contains(data.extra_data.variation_effects, "variation_draw") and not player.dead then
      player:drawCards(1, rule.name)
    end
    if table.contains(data.extra_data.variation_effects, "variation_damage") then
      data.additionalDamage = (data.additionalDamage or 0) + 1
    end
    if table.contains(data.extra_data.variation_effects, "variation_cancel") and not player.dead and
      data.responseToEvent and data.toCard and room:getCardArea(data.toCard) == Card.Processing then
      room:obtainCard(player, data.toCard, true, fk.ReasonJustMove, player, rule.name)
    end
  end,
})

return rule
