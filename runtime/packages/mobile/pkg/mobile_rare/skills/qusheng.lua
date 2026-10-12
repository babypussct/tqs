local qusheng = fk.CreateSkill {
  name = "qusheng",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qusheng"] = "驱乘",
  [":qusheng"] = "锁定技，你使用【杀】无距离限制，且不因此技能使用的【杀】只能指定上家/下家为目标。"..
  "当你使用指定唯一目标的【杀】结算后，若此【杀】目标角色的上家/下家不是你且未造成伤害，此【杀】不计入次数，然后你视为对其上家/下家使用一张普通【杀】。",

  ["$qusheng1"] = "今日驱车应敌，让蜀军见识我铁车的厉害。",
  ["$qusheng2"] = "便用此车，击败汝等小儿。",
}

qusheng:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    local to = data.tos[1]
    return target == player and player:hasSkill(qusheng.name) and
      data.card.trueName == "slash" and not data.damageDealt and to and data:isOnlyTarget(to) and
      (to:getNextAlive() ~= player or to:getLastAlive() ~= player)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if not data.extraUse then
      player:addCardUseHistory(data.card.trueName, -1)
      data.extraUse = true
    end
    local to = data.tos[1]
    -- 优先选择上一张“驱乘”杀的方向
    local victim, direction
    if data.extra_data and data.extra_data.qusheng then
      if data.extra_data.qusheng == "counterclockwise" then
        if to:getNextAlive() ~= player then
          victim = to:getNextAlive()
          direction = "counterclockwise"
        end
      else
        if to:getLastAlive() ~= player then
          victim = to:getLastAlive()
          direction = "clockwise"
        end
      end
    end
    if not victim then
      if to:getNextAlive() ~= player then
        victim = to:getNextAlive()
        direction = "counterclockwise"
      elseif to:getLastAlive() ~= player then
        victim = to:getLastAlive()
        direction = "clockwise"
      end
    end
    if not victim then return end
    room:useVirtualCard("slash", {}, player, victim, qusheng.name, true, { qusheng = direction })
  end,
})

qusheng:addEffect("targetmod", {
  bypass_distances = function (self, player, skill, card, to)
    return player:hasSkill(qusheng.name) and card and card.trueName == "slash"
  end,
})

qusheng:addEffect("prohibit", {
  is_prohibited = function (self, from, to, card)
    if from:hasSkill(qusheng.name) and card and card.trueName == "slash" and
      not table.contains(card.skillNames, qusheng.name) then
      return to:getNextAlive() ~= from and from:getNextAlive() ~= to
    end
  end,
})

return qusheng
