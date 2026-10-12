local zisheng = fk.CreateSkill {
  name = "zisheng",
}

Fk:loadTranslationTable{
  ["zisheng"] = "恣胜",
  [":zisheng"] = "你使用点数大于3且为3的倍数的牌时，可以从牌堆中随机三张点数为3的牌（若多张牌则点数相加），选择其中一张获得；"..
    "你弃置或获得其他角色牌时，可以对该角色造成与弃置或获得牌数相等的伤害（不超过该角色当前体力值）。",

  ["#zisheng-draw"] = "恣胜：你可以从三张点数为3的牌中获得一张",
  ["#zisheng-damage"] = "恣胜：你可以对 %dest 造成%arg点伤害",

  ["$zisheng1"] = "当阳立马，江州裂枷，擒崖前弃驹，敌万众者何人！",
  ["$zisheng2"] = "目极八荒，无一合之将，苍生仰面，谁！视我锋芒！",
}

zisheng:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(zisheng.name) then
      --待定：不知道和十周年的界禁酒的联动如何，无法测试
      local x = 0
      for _, id in ipairs(Card:getIdList(data.card)) do
        x = x + Fk:getCardById(id).number
      end
      return x > 3 and x % 3 == 0
    end
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = zisheng.name,
      prompt = "#zisheng-draw",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local skillName = zisheng.name
    local cards = room:getCardsFromPileByRule(".|3", 3)
    if #cards == 0 then return end
    local id = room:askToChooseCard(player, {
      target = target,
      flag = {
        card_data = {
          { skillName, cards }
        }
      },
      skill_name = skillName
    })
    room:obtainCard(player, id, false, fk.ReasonJustMove, player, skillName)
  end,
})

---@param player ServerPlayer
---@return boolean
local targetFilter = function(player)
  return not player.dead and player.hp > 0
end

---@param player ServerPlayer
---@param data MoveCardsData[]
---@return ServerPlayer[]
local getTargets = function(player, data)
  local targets = {}
  for _, move in ipairs(data) do
    if move.moveReason == fk.ReasonDiscard then
      if move.from and move.from ~= player and not table.contains(targets, move.from) and move.proposer == player then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            table.insert(targets, move.from)
            break
          end
        end
      end
    else
      --实测交给也算
      if move.from and move.from ~= player and not table.contains(targets, move.from) and
        (move.to == player and move.toArea == Card.PlayerHand) then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            table.insert(targets, move.from)
            break
          end
        end
      end
    end
  end
  return table.filter(targets, function(p)
    return targetFilter(p)
  end)
end

zisheng:addEffect(fk.AfterCardsMove, {
  anim_type = "offensive",
  trigger_times = function(self, event, target, player, data)
    local targets = event:getSkillData(self, self.name .. ":" .. player.id)
    if targets then
      return #table.filter(targets.unDone, function(p)
        return targetFilter(p)
      end) + (event.invoked_times[self.name] or 0)
    else
      return #getTargets(player, data)
    end
  end,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zisheng.name)
  end,
  on_trigger = function(self, event, target, player, data)
    event:setSkillData(self, "cancel_cost", false)
    self:doCost(event, target, player, data)
    event:setSkillData(self, "cancel_cost", false)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = event:getSkillData(self, self.name .. ":" .. player.id)
    local to
    if targets then
      while #targets.unDone > 0 do
        local p = table.remove(targets.unDone, 1)
        table.insert(targets.done, p)
        if targetFilter(p) then
          to = p
          break
        end
      end
    else
      targets = getTargets(player, data)
      if #targets > 0 then
        room:sortByAction(targets)
        to = table.remove(targets, 1)
        event:setSkillData(self, self.name .. ":" .. player.id, { done = { to }, unDone = targets })
      end
    end
    if to then
      local x = 0
      for _, move in ipairs(data) do
        if move.moveReason == fk.ReasonDiscard then
          if move.from and move.from ~= player and not table.contains(targets, move.from) and move.proposer == player then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                x = x + 1
              end
            end
          end
        else
          if move.from and move.from ~= player and not table.contains(targets, move.from) and
            (move.to == player and move.toArea == Card.PlayerHand) then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                x = x + 1
              end
            end
          end
        end
      end
      x = math.min(x, to.hp)
      if x > 0 and room:askToSkillInvoke(player, {
        skill_name = zisheng.name,
        prompt = "#zisheng-damage::"..to.id..":"..x,
      }) then
        event:setCostData(self, { tos = { to }, extra_data = x })
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local dat = event:getCostData(self)
    player.room:damage {
      from = player,
      to = dat.tos[1],
      damage = dat.extra_data,
      skillName = zisheng.name,
    }
  end,
})

zisheng:addAI(Fk.Ltk.AI.newInvokeStrategy{
  think = function(self, ai)
    if ai.data[2] == "#zisheng-draw" then
      return true
    else
      local target = ai.room:getPlayerById(tonumber(string.split(ai.data[2], ":")[3]))
      local n = tonumber(string.split(ai.data[2], ":")[4])
      return ai:getBenefitOfEvents(function(logic)
        logic:damage{
          from = ai.player,
          to = target,
          damage = n,
        }
      end) >= 0
    end
  end,
})

return zisheng
