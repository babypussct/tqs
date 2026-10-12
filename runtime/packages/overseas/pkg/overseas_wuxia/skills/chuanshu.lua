local chuanshu = fk.CreateSkill {
  name = "os__chuanshu",
}

Fk:loadTranslationTable{
  ["os__chuanshu"] = "传术",
  [":os__chuanshu"] = "出牌阶段限一次，你可以选择一名角色，直到你下回合开始：其拼点牌点数+5，" ..
  "其使用下一张【杀】对除你以外的角色造成伤害+1，此【杀】造成伤害时，你摸X+1张牌（X为此伤害值）。",

  ["#os__chuanshu"] = "传术：令一名角色直到你下回合开始：拼点牌点数+5，下一张【杀】伤害+1，造成伤害时你摸牌",
  ["@@os__chuanshu"] = "传术",

  ["$os__chuanshu1"] = "此术集百家之法，当传万世。",
  ["$os__chuanshu2"] = "某虽无名于世，此术可传之万年。",
}

chuanshu:addEffect("active", {
  anim_type = "support",
  prompt = "#os__chuanshu",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(chuanshu.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMark(target, "@@os__chuanshu", player.general)
    room:addTableMark(target, "_os__chuanshu_slash", player.id)
    room:addTableMark(player, "_os__chuanshu", {target.id, player.general})
  end,
})

chuanshu:addEffect(fk.DamageCaused, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:getMark("@@os__chuanshu") == 0 then return false end
    local parentUseEvent = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if parentUseEvent then
      local parentUseData = parentUseEvent.data
      if parentUseData.card == data.card and (parentUseData.extra_data or {}).os__chuanshuUser == player.id then
        local froms = (parentUseData.extra_data or {}).os__chuanshuSource
        return #froms > 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = chuanshu.name
    local room = player.room
    local parentUseData = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if parentUseData == nil then return end

    local froms = (parentUseData.data.extra_data or {}).os__chuanshuSource
    table.removeOne(froms, data.to.id)
    data:changeDamage(#froms)
    for _, pid in ipairs(froms) do
      local p = room:getPlayerById(pid)
      if p:isAlive() then
        p:drawCards(data.damage + 1, skillName)
      end
    end
  end,
})

chuanshu:addEffect(fk.PindianCardsDisplayed, {
  anim_type = "special",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@@os__chuanshu") ~= 0 and (data.from == player or table.contains(data.tos, player))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local num = 5 * #player:getMark("@@os__chuanshu")
    room:changePindianNumber(data, player, num, chuanshu.name)
  end,
})

chuanshu:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("_os__chuanshu") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, dat in ipairs(player:getMark("_os__chuanshu")) do
      room:removeTableMark(room:getPlayerById(dat[1]), "@@os__chuanshu", dat[2])
    end
    room:setPlayerMark(player, "_os__chuanshu", 0)
  end,
})

chuanshu:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("_os__chuanshu_slash") ~= 0 and data.card.trueName == "slash"
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    data.extra_data = data.extra_data or {}
    data.extra_data.os__chuanshuUser = player.id
    data.extra_data.os__chuanshuSource = player:getMark("_os__chuanshu_slash")
    room:setPlayerMark(player, "_os__chuanshu_slash", 0)
  end,
})

chuanshu:addEffect(fk.BuryVictim, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("_os__chuanshu") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, dat in ipairs(player:getMark("_os__chuanshu")) do
      room:removeTableMark(room:getPlayerById(dat[1]), "@@os__chuanshu", dat[2])
    end
    room:setPlayerMark(player, "_os__chuanshu", 0)
  end,
})

return chuanshu
