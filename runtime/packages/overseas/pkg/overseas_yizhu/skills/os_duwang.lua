local osDuwang = fk.CreateSkill {
  name = "os__duwang",
  tags = { Skill.Quest },
  related_skills = { "os__xiayong" },
}

Fk:loadTranslationTable{
  ["os__duwang"] = "独往",
  [":os__duwang"] = "<a href='os__quest'>使命技</a>，出牌阶段开始时，你可以选择至多三名其他角色并摸X+1张牌，" ..
  "然后令这些角色依次将一张牌当【决斗】对你使用（X为你以此法选择的角色数）。<br>"..
  "⬤　成功：准备阶段，若你的上个回合你使用【决斗】与成为【决斗】目标的次数之和不小于4（若游戏人数小于4则改为3），你选择一项：" ..
  "1.获得〖狭勇〗；2.你视为未发动过〖延势〗并修改之。" ..
  "⬤　完成前：当你处于濒死状态时，其他角色不能对你使用【桃】。",

  ["os__duwang_obtain_xiayong"] = "获得〖狭勇〗",
  ["os__duwang_upgrade_yanshi"] = "复原并修改〖延势〗",
  ["#os__duwang-invoke"] = "独往：选择至多三名其他角色并摸等量+1张牌，这些角色依次将一张牌当【决斗】对你使用",
  ["@@os__yanshiUp"] = "延势 已升级",
  ["#os__duwang-duel"] = "独往：将一张牌当【决斗】对 %dest 使用",

  ["$os__duwang1"] = "阿瞒聚众来犯，吾一人可挡万敌！",
  ["$os__duwang2"] = "勇绝河北，吾足以一柱擎天！",
}

osDuwang:addEffect(fk.EventPhaseStart, {
  can_trigger = function (self, event, target, player, data)
    return
      target == player and
      player:hasSkill(osDuwang.name) and
      (
        player.phase == Player.Play or
        (
          player.phase == Player.Start and
          player:getMark("_os__duwang") > 0 and
          player:getQuestSkillState(osDuwang.name) ~= "succeed"
        )
      )
  end,
  on_cost = function (self, event, target, player, data)
    ---@type string
    local skillName = osDuwang.name
    local room = player.room
    if player.phase == Player.Start then
      event:setCostData(
        self,
        room:askToChoice(
          player,
          {
            choices = { "os__duwang_obtain_xiayong", "os__duwang_upgrade_yanshi" },
            skill_name = skillName,
          }
        )
      )
      return true
    else
      local tos = room:askToChoosePlayers(
        player,
        {
          targets = room:getOtherPlayers(player, false),
          min_num = 1,
          max_num = 3,
          prompt = "#os__duwang-invoke",
          skill_name = skillName,
        }
      )
      if #tos > 0 then
        event:setCostData(self, { tos = tos })
        return true
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    ---@type string
    local skillName = osDuwang.name
    local room = player.room
    if player.phase == Player.Start then
      room:updateQuestSkillState(player, skillName, true)
      room:updateQuestSkillState(player, skillName, false)
      local choice = event:getCostData(self)
      if choice == "os__duwang_obtain_xiayong" then
        room:handleAddLoseSkills(player, "os__xiayong")
      else
        room:setPlayerMark(player, "@@os__yanshiUp", 1)
        player:setSkillUseHistory("os__yanshih", 0, Player.HistoryGame)
      end
    else
      local tos = event:getCostData(self).tos ---@type ServerPlayer[]
      local num = #tos
      player:drawCards(num + 1, skillName)
      if not player:isAlive() then
        return
      end

      for _, to in ipairs(tos) do
        if to:isAlive() and player:isAlive() then
          room:askToUseVirtualCard(to, {
            name = "duel",
            skill_name = osDuwang.name,
            prompt = "#os__duwang-duel::" .. player.id,
            cancelable = false,
            extra_data = {
              exclusive_targets = { player.id },
            },
            card_filter = {
              n = 1,
            },
          })
        end
      end
    end
  end,
})

osDuwang:addEffect(fk.TurnEnd, {
  can_refresh = function (self, event, target, player)
    return target == player and player:hasSkill(osDuwang.name) and player:getQuestSkillState(osDuwang.name) ~= "succeed"
  end,
  on_refresh = function (self, event, target, player)
    local room = player.room
    local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
    if turn_event == nil then
      return false
    end

    local end_id = turn_event.id
    local num = #room.players < 4 and 3 or 4
    if #room.logic:getEventsByRule(GameEvent.UseCard, num, function (e)
      local use = e.data
      return
        use.card.trueName == "duel" and
        (use.from == player or table.contains(use.tos, player))
    end, end_id) == num then
      room:setPlayerMark(player, "_os__duwang", 1)
    end
  end,
})

osDuwang:addEffect("prohibit", {
  is_prohibited = function (self, from, to, card)
    return
      card.trueName == "peach" and
      to:hasSkill(osDuwang.name) and
      to:getQuestSkillState(osDuwang.name) ~= "succeed" and
      from ~= to
  end,
})

return osDuwang
