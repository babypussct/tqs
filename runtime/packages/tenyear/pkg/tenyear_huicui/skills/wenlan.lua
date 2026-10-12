local wenlan = fk.CreateSkill {
  name = "wenlan",
}

Fk:loadTranslationTable{
  ["wenlan"] = "文澜",
  [":wenlan"] = "你每使用或打出两张牌结算后：若为包含相同牌名的两张“赋”，你从牌堆中获得这两张“赋”中所含牌名的牌各一张，并标记为“赋”；"..
  "否则你选择任意张手牌标记为“赋”或替换“赋”牌名。",

  ["#wenlan-cards"] = "文澜：选择任意张手牌标记为“赋”或替换“赋”牌名",

  ["$wenlan1"] = "胸中万仞，寥落纸上数言。",
  ["$wenlan2"] = "欲写当年白马篇，笺已破，笔已残。",
}

local getFuYueName = function(data)
  local infos = data.subcardsFromInfo
  if infos and #infos == 1 then
    local info = infos[1]
    local name = info.beforeCard:getMark("@fuyue-inhand")
    if name ~= 0 then
      return { Fk:getCardById(info.cardId).trueName, name }
    end
  end
  return {}
end

local diffTable = function(t1, t2)
  local a1,a2 = t1[1],t1[2]
  local b1,b2 = t2[1],t2[2]
  local hasInter = a1==b1 or a1==b2 or a2==b1 or a2==b2
  if not hasInter then
      return nil
  end
  local mark = {}
  local res = {}
  local idx = 0
  if not mark[a1] then mark[a1]=true idx=idx+1 res[idx]=a1 end
  if not mark[a2] then mark[a2]=true idx=idx+1 res[idx]=a2 end
  if not mark[b1] then mark[b1]=true idx=idx+1 res[idx]=b1 end
  if not mark[b2] then mark[b2]=true idx=idx+1 res[idx]=b2 end
  return res
end

---@type TrigSkelSpec<RespondCardFunc>
local spec = {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if data.from == player and data.card.sub_type ~= Card.SubtypeDelayedTrick and player:hasSkill(wenlan.name) then
      local logic = player.room.logic
      local start_id = logic:getCurrentEvent().id
      local end_id = player:getMark("wenlan_lastEventId")
      local events = logic.all_game_events or Util.DummyTable
      local names = getFuYueName(data)
      for i = start_id-1, end_id+1, -1 do
        local e = events[i]
        if e.event == GameEvent.UseCard or e.event == GameEvent.RespondCard then
          local use = e.data
          if use.from == player and use.card.sub_type ~= Card.SubtypeDelayedTrick then
            if #names == 2 then
              local names2 = getFuYueName(use)
              if #names2 == 2 then
                names = diffTable(names, names2)
              else
                names = nil
              end
            else
              names = nil
            end
            event:setCostData(self, { extra_data = names })
            return true
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local e = room.logic:getCurrentEvent().parent
    if e then
      room:setPlayerMark(player, "wenlan_lastEventId", e.id)
    end
    local names = event:getCostData(self).extra_data
    if names then
      local cards = {}
      local drawpile = room.draw_pile
      for i = #drawpile, 1, -1 do
        local id = drawpile[i]
        if table.removeOne(names, Fk:getCardById(id).trueName) then
          table.insert(cards, id)
          if #names == 0 then break end
        end
      end
      if #cards > 0 then
        names = Fk:getAllCardNames("btd", true)
        local moves = {}
        for _, id in ipairs(cards) do
          local card = Fk:getCardById(id, true)
          local name = card.trueName
          local names2 = table.filter(names, function(n)
            return n ~= name
          end)
          name = nil
          if #names2 > 0 then
            name = room:tableRandomPick(names2)
          end
          table.insert(moves, {
            ids = { id },
            to = player,
            toArea = Card.PlayerHand,
            moveReason = fk.ReasonJustMove,
            proposer = player,
            skillName = wenlan.name,
            moveVisible = false,
            moveMark = { "@fuyue-inhand", name },
          })
        end
        room:moveCards(table.unpack(moves))
      end
    elseif not player:isKongcheng() then
      local cards = room:askToCards(player, {
        min_num = 1,
        max_num = player:getHandcardNum(),
        include_equip = false,
        skill_name = wenlan.name,
        cancelable = false,
        prompt = "#wenlan-cards",
      })
      names = Fk:getAllCardNames("btd", true)
      for _, id in ipairs(cards) do
        local card = Fk:getCardById(id, true)
        local names2 = table.filter(names, function(n)
          return n ~= card.trueName and n ~= card:getMark("@fuyue-inhand")
        end)
        if #names2 > 0 then
          room:setCardMark(card, "@fuyue-inhand", room:tableRandomPick(names2))
        end
      end
    end
  end,
}

wenlan:addEffect(fk.CardUseFinished, spec)
wenlan:addEffect(fk.CardRespondFinished, spec)

wenlan:addLoseEffect(function(self, player, is_death)
  player.room:setPlayerMark(player, "wenlan_lastEventId", 0)
end)

return wenlan
