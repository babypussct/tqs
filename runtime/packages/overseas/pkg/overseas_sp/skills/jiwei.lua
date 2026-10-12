local jiwei = fk.CreateSkill{
  name = "os__jiwei",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__jiwei"] = "济危",
  [":os__jiwei"] = "锁定技，每名其他角色的回合结束时，若此回合有角色失去过牌，你摸两张牌；若本回合有角色受到过伤害，你摸两张牌。<br>"..
  "准备阶段，若所有角色均存活，且你的手牌数不小于五，则你须将手牌中数量较多颜色的牌全部分配给其他角色（若数量相同则选择一种颜色）。",

  ["#os__jiwei-choice"] = "济危：请选择一种颜色，将此颜色的手牌分配给其他角色",
  ["#os__jiwei-give"] = "济危：请将%arg手牌分配给其他角色",

  ["$os__jiwei1"] = "戴群星之璀粲，妆百花之盛颜，可为悦已者容。",
  ["$os__jiwei2"] = "撷首阳之野芳，缀沧海之鲛珠，独善此世之白。",
}

jiwei:addEffect(fk.TurnEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target ~= player and player:hasSkill(jiwei.name) then
      local room = player.room
      local n = 0
      if #room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.from then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                return true
              end
            end
          end
        end
      end, Player.HistoryTurn) > 0 then
        n = 2
      end
      if #room.logic:getActualDamageEvents(1, Util.TrueFunc, Player.HistoryTurn) > 0 then
        n = n + 2
      end
      if n > 0 then
        event:setCostData(self, {choice = n})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(event:getCostData(self).choice, jiwei.name)
  end,
})

jiwei:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiwei.name) and player.phase == Player.Start and
      #player.room:getOtherPlayers(player, false) > 0 and
      #player.room.players == #player.room.alive_players and player:getHandcardNum() >= 5
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local red = table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id).color == Card.Red
    end)
    local black = table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id).color == Card.Black
    end)
    local color = ""
    if #red > #black then
      color = "red"
    elseif #red < #black then
      color = "black"
    else
      if #red == 0 then return end
      color = room:askToChoice(player, {
        choices = {"red", "black"},
        skill_name = jiwei.name,
        prompt = "#os__jiwei-choice",
      })
    end
    local cards = red
    if color == "black" then
      cards = black
    end
    room:askToYiji(player, {
      min_num = #cards,
      max_num = #cards,
      skill_name = jiwei.name,
      targets = room:getOtherPlayers(player, false),
      cards = cards,
      prompt = "#os__jiwei-give:::"..color,
    })
  end,
})

return jiwei
