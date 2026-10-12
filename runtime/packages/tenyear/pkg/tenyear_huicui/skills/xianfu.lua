local xianfu = fk.CreateSkill {
  name = "xianful",
}

Fk:loadTranslationTable{
  ["xianful"] = "娴辅",
  [":xianful"] = "每回合限一次，当你成为牌目标时，你可以跳过你下回合的除准备阶段和结束阶段外的一个阶段令此牌对你无效，"..
    "然后你与“明节”角色互相观看手牌并各可以获得对方的至多三张手牌。",

  ["#xianful-choice"] = "娴辅：是否跳过你下回合的阶段并与%dest交换至多三张手牌，令%arg对你无效？",
  ["#xianful-cards"] = "娴辅：你可以获得%dest的至多3张手牌",

  ["$xianful1"] = "愿陛下揽镜，察尽天下秋毫。",
  ["$xianful2"] = "治世如棋，急则生乱，缓则失机。",
}

xianfu:addEffect(fk.TargetConfirming, {
  anim_type = "defensive",
  max_turn_use_time = 1,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(xianfu.name) and self:withinTimesLimit(player) and
      #player:getTableMark(xianfu.name) < 4 then
      local to = player:getMark("mingjiel")
      return to ~= 0 and not to.dead
    end
  end,
  on_cost = function(self, event, target, player, data)
    local to = player:getMark("mingjiel")
    local choices = { "phase_judge", "phase_draw", "phase_play", "phase_discard" }
    for _, phase in ipairs(player:getTableMark(xianfu.name)) do
      table.removeOne(choices, Util.PhaseStrMapper(phase))
    end
    local choice = player.room:askToChoice(player, {
      choices = choices,
      skill_name = xianfu.name,
      prompt = "#xianful-choice::" .. to.id .. ":" .. data.card:toLogString(),
      cancelable = true
    })
    if choice ~= "Cancel" then
      event:setCostData(self, { tos = { to }, extra_data = choice })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dat = event:getCostData(self)
    room:addTableMark(player, xianfu.name, Util.PhaseStrMapper(dat.extra_data))
    data.nullified = true

    local to = dat.tos[1]

    local req = Request:new({ player, to }, "AskForPoxi")
    req.focus_text = xianfu.name
    req.receive_decode = false

    req:setData(player, {
      type = "AskForCardsChosen",
      data = { { to.general, to:getCardIds("h") } },
      extra_data = {
        to = to.id,
        min = 1,
        max = 3,
        skillName = xianfu.name,
        prompt = "#xianful-cards::"..to.id,
        pattern = ".",
      },
      cancelable = true,
    })

    req:setData(to, {
      type = "AskForCardsChosen",
      data = { { player.general, player:getCardIds("h") } },
      extra_data = {
        to = player.id,
        min = 1,
        max = 3,
        skillName = xianfu.name,
        prompt = "#xianful-cards::"..player.id,
        pattern = ".",
      },
      cancelable = true,
    })

    req:ask()
    local ids1 = req:getResult(player)
    if ids1 == "" then
      ids1 = {}
    end
    local ids2 = req:getResult(to)
    if ids2 == "" then
      ids2 = {}
    end
    if #ids1 > 0 or #ids2 > 0 then
      room:swapCards(player, {
        {player, ids2},
        {to, ids1}
      }, xianfu.name)
    end
  end,
})

xianfu:addEffect(fk.EventPhaseChanging, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and not data.skipped and player:hasSkill(xianfu.name) and
      table.contains(player:getTableMark(xianfu.name), data.phase)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    --神秘设定，是通过发动明节摸牌来恢复选项的
    --现象1：同时中兵乐，且娴辅跳出牌，此时因为没有“出牌阶段开始前”，娴辅不会发动，但是能重置选项
    --现象2：发动娴辅跳阶段时因滤心失去体力至1点且缠怨的情况下，选项不会恢复
    --现象3：出牌阶段发动娴辅选跳出牌，结束出牌阶段时因观微获得额外出牌阶段，此阶段会因娴辅被跳过，但是不会重置选项
    --if data.reason == "game_rule" then
    --  player.room:removeTableMark(player, xianfu.name, data.phase)
    --end
    data.skipped = true
  end,
})

xianfu:addLoseEffect(function(self, player, is_death)
  player.room:setPlayerMark(player, xianfu.name, 0)
end)

return xianfu
