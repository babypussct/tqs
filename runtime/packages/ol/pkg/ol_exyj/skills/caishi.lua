local caishi = fk.CreateSkill{
  name = "ol_ex__caishi",
}

Fk:loadTranslationTable{
  ["ol_ex__caishi"] = "才识",
  [":ol_ex__caishi"] = "当你每轮首次使用一种类别的牌后，你本轮手牌上限+1。"..
  "然后若你的手牌上限为全场最大，你可以令一名角色回复1点体力，然后此技能本回合失效。",

  ["#ol_ex__caishi-choose"] = "才识：你可以令一名角色回复1点体力，此技能本回合失效",

  ["$ol_ex__caishi1"] = "入则致孝于亲，出则致节于国。",
  ["$ol_ex__caishi2"] = "在职思其所司，在义思其所立。",
}

caishi:addEffect(fk.CardUseFinished, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(caishi.name) then
      local card_type = data.card.type
      local room = player.room
      local use_event = room.logic:getCurrentEvent()
      local mark_name = "ol_ex__caishi_" .. data.card:getTypeString() .. "-round"
      local mark = player:getMark(mark_name)
      if mark == 0 then
        room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
          local last_use = e.data
          if last_use.from == player and last_use.card.type == card_type then
            mark = e.id
            room:setPlayerMark(player, mark_name, mark)
            return true
          end
          return false
        end, Player.HistoryRound)
      end
      return mark == use_event.id
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, MarkEnum.AddMaxCards.."-round", 1)
    if table.every(room.alive_players, function (p)
      return p == player or p:getMaxCards() < player:getMaxCards()
    end) then
      local targets = table.filter(room.alive_players, function (p)
        return p:isWounded()
      end)
      if #targets == 0 then
        return false
      end

      local to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#ol_ex__caishi-choose",
        skill_name = caishi.name,
        cancelable = true,
      })
      if #to > 0 then
        room:invalidateSkill(player, caishi.name, "-turn")
        room:recover{
          who = to[1],
          num = 1,
          recoverBy = player,
          skillName = caishi.name,
        }
      end
    end
  end,
})

return caishi
