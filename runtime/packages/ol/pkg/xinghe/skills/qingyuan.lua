local qingyuan = fk.CreateSkill{
  name = "qingyuan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qingyuan"] = "轻缘",
  [":qingyuan"] = "锁定技，游戏开始时，你选择一名其他角色；当你首次受到伤害后，你再选择一名其他角色。"..
  "每回合限一次，当以此法选择的角色获得牌后，你获得其中随机一名角色的随机一张手牌。",

  ["#qingyuan-choose"] = "轻缘：选择一名其他角色",
  ["@@qingyuan"] = "轻缘",

  ["$qingyuan1"] = "男儿重义气，自古轻别离。",
  ["$qingyuan2"] = "缘轻义重，倚东篱而叹长生。",
}

qingyuan:addLoseEffect(function (self, player, is_death)
  local room = player.room
  for _, id in ipairs(player:getTableMark("qingyuan_target")) do
    local p = room:getPlayerById(id)
    if not p.dead and not table.find(room:getOtherPlayers(player, false), function (q)
      return table.contains(q:getTableMark("qingyuan_target"), p.id)
    end) then
      room:setPlayerMark(p, "@@qingyuan", 0)
    end
  end
  room:setPlayerMark(player, "qingyuan_target", 0)
end)

local qingyuan_spec = {
  on_use = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return not table.contains(player:getTableMark("qingyuan_target"), p.id)
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = qingyuan.name,
      prompt = "#qingyuan-choose",
      cancelable = false,
    })[1]
    room:addTableMark(player, "qingyuan_target", to.id)
    room:setPlayerMark(to, "@@qingyuan", 1)
  end,
}

qingyuan:addEffect(fk.GameStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(qingyuan.name) and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return not table.contains(player:getTableMark("qingyuan_target"), p.id)
      end)
  end,
  on_use = qingyuan_spec.on_use,
})
qingyuan:addEffect(fk.Damaged, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    if target == player and player:hasSkill(qingyuan.name) then
      local mark = player:getMark("qingyuan_damage")
      local room = player.room
      if mark == 0 then
        room.logic:getActualDamageEvents(1, function (e)
          local damage = e.data
          if damage.to == player then
            mark = e.id
            room:setPlayerMark(player, "qingyuan_damage", mark)
            return true
          end
          return false
        end, Player.HistoryGame)
      end
      return room.logic:getCurrentEvent().id == mark and
        table.find(player.room:getOtherPlayers(player, false), function (p)
          return not table.contains(player:getTableMark("qingyuan_target"), p.id)
        end)
    end
  end,
  on_use = qingyuan_spec.on_use,
})
qingyuan:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    local room = player.room
    if player:hasSkill(qingyuan.name) and room:getCurrent() and player:usedEffectTimes(self.name, Player.HistoryTurn) == 0 and
      player:getMark("qingyuan_target") ~= 0 then
      for _, move in ipairs(data) do
        if move.to and table.contains(player:getTableMark("qingyuan_target"), move.to.id) and move.toArea == Card.PlayerHand then
          local targets = {}
          local p
          for _, id in ipairs(player:getTableMark("qingyuan_target")) do
            p = room:getPlayerById(id)
            if not (p.dead or p:isKongcheng()) then
              table.insertIfNeed(targets, p)
            end
          end
          if #targets > 0 then
            event:setCostData(self, { tos = targets })
            return true
          else
            return
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:tableRandomPick(event:getCostData(self).tos)
    room:obtainCard(player, room:tableRandomPick(to:getCardIds("h")), false, fk.ReasonPrey, player, qingyuan.name)
  end,
})
return qingyuan
