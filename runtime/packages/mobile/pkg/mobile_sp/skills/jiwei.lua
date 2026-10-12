local jiwei = fk.CreateSkill{
  name = "jiwei",
  tags = { Skill.Compulsory },
  dynamic_desc = function(self, player)
    if Fk:currentRoom():isGameMode("1v2_mode") then
      return "jiwei_1v2"
    elseif Fk:currentRoom():isGameMode("2v2_mode") then
      return "jiwei_2v2"
    else
      return "jiwei_role_mode"
    end
  end,
}

Fk:loadTranslationTable{
  ["jiwei"] = "济危",
  [":jiwei"] = "锁定技，其他角色的回合结束时，此回合每满足一项，你便摸一张牌：<br>"..
  "1.有角色失去过牌；<br>2.有角色受到过伤害（若为身份模式，则移除此项；若为斗地主，则满足此项额外摸一张牌）。<br>"..
  "准备阶段，若你的手牌数不小于存活人数且不小于你的体力值（若为斗地主或2v2模式，则此条件改为若所有角色均存活且你的手牌数不少于五张），" ..
  "则你须将手牌中数量较多颜色的牌全部分配给其他角色（若数量相同则选择一种颜色）。",

  [":jiwei_1v2"] = "锁定技，其他角色的回合结束时，若此回合：有角色失去过牌，你摸一张牌；有角色受到过伤害，你摸两张牌。<br>"..
  "准备阶段，若所有角色均存活且你的手牌数不少于五张，则你须将手牌中数量较多颜色的牌全部分配给其他角色（若数量相同则选择一种颜色）。",
  [":jiwei_role_mode"] = "锁定技，其他角色的回合结束时，若此回合有角色失去过牌，你摸一张牌。<br>"..
  "准备阶段，若你的手牌数不小于存活人数且不小于你的体力值，则你须将手牌中数量较多颜色的牌全部分配给其他角色（若数量相同则选择一种颜色）。",
  [":jiwei_2v2"] = "锁定技，其他角色的回合结束时，此回合每满足一项，你便摸一张牌：<br>"..
  "1.有角色失去过牌；<br>2.有角色受到过伤害。<br>"..
  "准备阶段，若你的手牌数不小于存活人数且不小于你的体力值，则你须将手牌中数量较多颜色的牌全部分配给其他角色（若数量相同则选择一种颜色）。",

  ["#jiwei-choice"] = "济危：请选择一种颜色，将此颜色的手牌分配给其他角色",
  ["#jiwei-give"] = "济危：请将%arg手牌分配给其他角色",

  ["$jiwei1"] = "乱世之宝，非金银田产，而在仁心。",
  ["$jiwei2"] = "匹夫怀璧为罪，更况吾豪门大族。",
  ["$jiwei3"] = "左右乡邻，当共力时艰。",
  ["$jiwei4"] = "民不逢时，吾又何忍视其饥苦。",
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
        n = n + 1
      end
      if not room:isGameMode("role_mode") and #room.logic:getActualDamageEvents(1, Util.TrueFunc, Player.HistoryTurn) > 0 then
        n = n + (room:isGameMode("1v2_mode") and 2 or 1)
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
    if target == player and player:hasSkill(jiwei.name) and player.phase == Player.Start and
      #player.room:getOtherPlayers(player, false) > 0 then
      local room = player.room
      if room:isGameMode("1v2_mode") or room:isGameMode("2v2_mode") then
        return #room.players == #room.alive_players and player:getHandcardNum() >= 5
      else
        return player:getHandcardNum() >= #room.alive_players and player:getHandcardNum() >= player.hp
      end
    end
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
        prompt = "#jiwei-choice",
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
      prompt = "#jiwei-give:::"..color,
    })
  end,
})

return jiwei
