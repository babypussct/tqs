local zenhui = fk.CreateSkill {
  name = "ol_ex__zenhui",
  max_branches_use_time = {
    ["draw"] = {
      [Player.HistoryTurn] = 1
    },
  },
}

Fk:loadTranslationTable{
  ["ol_ex__zenhui"] = "谮毁",
  [":ol_ex__zenhui"] = "当你使用【杀】或普通锦囊牌（不含【借刀杀人】）指定目标时，你可以令另一名能成为此牌目标的其他角色选择一项："..
  "1.交给你一张牌并代替你成为此牌的使用者（不计次数）；2.成为此牌的额外目标。若选项与上次不同，你摸一张牌（每回合限一次）。",

  ["#ol_ex__zenhui-choose"] = "谮毁：你可以令一名角色选择：交给你一张牌并成为此牌的使用者；或成为此牌的额外目标",

  ["$ol_ex__zenhui1"] = "父疾，而子不侍，此为不孝。",
  ["$ol_ex__zenhui2"] = "君患，而臣不忧，是为不忠。"
}

zenhui:addEffect(fk.TargetSpecifying, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zenhui.name) and data.firstTarget and
      (data.card.trueName == "slash" or (data.card.trueName ~= "collateral" and data.card:isCommonTrick())) and
      table.find(data:getExtraTargets({ bypass_times = true }), function (p)
        return p ~= player
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(data:getExtraTargets({ bypass_times = true }), function (p)
        return p ~= player
      end)
    local to = room:askToChoosePlayers(player, {
      skill_name = zenhui.name,
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#ol_ex__zenhui-choose:::"..data.card:toLogString(),
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local choice = player:getMark(zenhui.name)
    local card = {}
    if not to:isNude() then
      card = room:askToCards(to, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = zenhui.name,
        prompt = "#zenhui-give::"..player.id,
        cancelable = true,
      })
    end
    local yes = true
    if choice == 0 then
      yes = false
    end
    if #card > 0 then
      room:setPlayerMark(player, zenhui.name, "give")
      if choice == "add" then
        yes = true
      end
      room:obtainCard(player, card, false, fk.ReasonGive, to, zenhui.name)
      data.from = to
      if not data.use.extraUse then
        data.use.extraUse = true
        player:addCardUseHistory(data.card.trueName, -1)
      end
    else
      room:setPlayerMark(player, zenhui.name, "add")
      if choice == "give" then
        yes = true
      end
      data:addTarget(to)
    end
    if yes and not player.dead and zenhui:withinBranchTimesLimit(player, "draw", Player.HistoryTurn) then
      player:addSkillBranchUseHistory(zenhui.name, "draw", 1)
      player:drawCards(1, zenhui.name)
    end
  end,
})

return zenhui
