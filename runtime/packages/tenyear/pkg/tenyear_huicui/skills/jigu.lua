local jigu = fk.CreateSkill {
  name = "jigu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jigu"] = "激鼓",
  [":jigu"] = "锁定技，游戏开始时，你的初始手牌增加“激鼓”标记且不计入手牌上限。当你造成或受到伤害后，若你手牌中的“激鼓”数等于"..
  "装备区牌数，你摸X张牌（X为你空置的装备栏数）；本轮内发动次数达到本局游戏已进入过回合的角色数后本轮失效。",

  ["@@jigu-inhand"] = "激鼓",

  ["$jigu1"] = "我接着奏乐，诸公接着舞！",
  ["$jigu2"] = "这不是鼓，而是曹公的脸面。",
}

jigu:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    if not player:isKongcheng() then
      local skillName = jigu.name
      --FIXME：须无视自身的封锁，这种写法很愚蠢
      local record = player:getTableMark(MarkEnum.InvalidSkills .. "-round")
      if record[skillName] and table.contains(record[skillName], skillName) then
        local room = player.room
        room:validateSkill(player, skillName, "-round")
        local can_invoke = player:hasSkill(skillName)
        room:invalidateSkill(player, skillName, "-round")
        return can_invoke
      else
        return player:hasSkill(skillName)
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(player:getCardIds("h")) do
      room:setCardMark(Fk:getCardById(id), "@@jigu-inhand", 1)
    end
  end,
})

local spec = {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jigu.name) and
      #table.filter(player:getCardIds("h"), function (id)
        return Fk:getCardById(id):getMark("@@jigu-inhand") > 0
      end) == #player:getCardIds("e") and
      #player:getAvailableEquipSlots() > #player:getCardIds("e")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark(jigu.name) < #room.players then
      local players = {}
      room.logic:getEventsOfScope(GameEvent.Turn, 1, function (e)
        table.insertIfNeed(players, e.data.who)
      end, Player.HistoryGame)
      room:setPlayerMark(player, jigu.name, #players)
    end
    if player:usedEffectTimes("#jigu_2_trig", Player.HistoryRound) +
      player:usedEffectTimes("#jigu_3_trig", Player.HistoryRound) >= player:getMark(jigu.name) then
      room:invalidateSkill(player, jigu.name, "-round")
    end
    local n = #player:getAvailableEquipSlots() - #player:getCardIds("e")
    player:drawCards(n, jigu.name)
  end,
}

jigu:addEffect(fk.Damage, spec)
jigu:addEffect(fk.Damaged, spec)

jigu:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return card:getMark("@@jigu-inhand") > 0
  end,
})

jigu:addLoseEffect(function (self, player, is_death)
  local room = player.room
  for _, id in ipairs(player:getCardIds("h")) do
    room:setCardMark(Fk:getCardById(id), "@@jigu-inhand", 0)
  end
end)

return jigu
