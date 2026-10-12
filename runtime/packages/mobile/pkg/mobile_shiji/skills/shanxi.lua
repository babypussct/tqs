local shanxi = fk.CreateSkill {
  name = "wisdom__shanxi",
}

Fk:loadTranslationTable{
  ["wisdom__shanxi"] = "善檄",
  [":wisdom__shanxi"] = "出牌阶段开始时，你可以令一名没有“檄”的角色获得一枚“檄”标记（若场上有该标记则改为转移至该角色）；当有“檄”标记的角色"..
  "回复体力后，若其不处于濒死状态，其须选择一项：1.交给你两张牌；2.失去1点体力。",

  ["#wisdom__shanxi-choose"] = "善檄：请选择一名其他角色获得“檄”标记（场上已有则转移标记至该角色）",
  ["@@wisdom__xi"] = "檄",
  ["#wisdom__shanxi-give"] = "善檄：请交给 %src 两张牌，否则失去1点体力",

  ["$wisdom__shanxi1"] = "西京乱无象，豺虎方遘患。",
  ["$wisdom__shanxi2"] = "复弃中国去，委身适荆蛮。",
}

shanxi:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shanxi.name) and player.phase == Player.Play and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return p:getMark("@@wisdom__xi") == 0
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return p:getMark("@@wisdom__xi") == 0
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = shanxi.name,
      prompt = "#wisdom__shanxi-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    for _, p in ipairs(room:getAlivePlayers()) do
      room:setPlayerMark(p, "@@wisdom__xi", 0)
    end
    room:setPlayerMark(to, "@@wisdom__xi", 1)
  end,
})
shanxi:addEffect(fk.HpRecover, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shanxi.name) and target:getMark("@@wisdom__xi") > 0 and not target.dying and not target.dead
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:doIndicate(player, {target})
    if #target:getCardIds("he") < 2 then
      room:loseHp(target, 1, shanxi.name)
      return
    end
    local cards = room:askToCards(target, {
      min_num = 2,
      max_num = 2,
      include_equip = true,
      skill_name = shanxi.name,
      prompt = "#wisdom__shanxi-give:"..player.id,
      cancelable = true,
    })
    if #cards == 2 then
      room:moveCardTo(cards, Player.Hand, player, fk.ReasonGive, shanxi.name, nil, false, target)
    else
      room:loseHp(target, 1, shanxi.name)
    end
  end,
})

return shanxi
