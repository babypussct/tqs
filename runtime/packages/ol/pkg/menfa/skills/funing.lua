local funing = fk.CreateSkill{
  name = "ol__funing",
}

Fk:loadTranslationTable{
  ["ol__funing"] = "抚宁",
  [":ol__funing"] = "每轮你的体力值首次变化后，你可以将至少X张牌交给一名角色（X为你已损失体力值且至少为1）。"..
    "若你交给的牌：颜色均相同，你回复1点体力；数量大于本回合受到过伤害的角色数，你将手牌调整至体力上限。",

  ["#ol__funing-target"] = "抚宁：将至少%arg张手牌交给1名角色，若交出牌数量大于%arg2将手牌调整至体力上限",

  ["$ol__funing1"] = "内外协一，方定天下社稷。",
  ["$ol__funing2"] = "屯田养战，此为乱世良方。",
}

local spec = {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player == target and player:hasSkill(funing.name) and
      #player:getCardIds("he") >= math.max(1, player:getLostHp()) then
      local room = player.room
      local g_event = room.logic:getCurrentEvent()
      local x = player:getMark("ol__funing_record-round")
      if x == 0 then
        room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function(e)
          if e.data.who == player then
            x = e.id
            room:setPlayerMark(player, "ol__funing_record-round", x)
            return true
          end
        end, Player.HistoryRound)
      end
      if x == 0 or x < g_event.id then return end
      return room.logic.all_game_events[x].parent == g_event
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local x = math.max(1, player:getLostHp())
    local players = {}
    room.logic:getActualDamageEvents(1, function(e)
      table.insertIfNeed(players, e.data.to)
    end, Player.HistoryTurn)
    local y = #players
    --FIXME：实测回合空隙也计算在内

    local tos, cards = room:askToChooseCardsAndPlayers(player, {
      min_num = 1,
      max_num = 1,
      min_card_num = x,
      max_card_num = 998,
      targets = room:getOtherPlayers(player, false),
      skill_name = funing.name,
      prompt = "#ol__funing-target:::" .. x .. ":" .. y,
      cancelable = true,
    })
    if #tos > 0 and #cards > 0 then
      event:setCostData(self, { tos = tos, cards = cards, extra_data = (#cards > y) })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local skillName = funing.name
    local dat = event:getCostData(self)
    local cards = dat.cards ---@type integer[]

    local color = Fk:getCardById(cards[1]).color
    if #cards == 1 then
      color = Card.Red
    else
      for i = 2, #cards, 1 do
        if color ~= Fk:getCardById(cards[i]).color then
          color = Card.NoColor
          break
        end
      end
    end

    room:moveCardTo(cards, Card.PlayerHand, dat.tos[1], fk.ReasonGive, skillName, nil, false, player)
    if player.dead then return end

    if color ~= Card.NoColor and player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = skillName
      }
      if player.dead then return end
    end

    if dat.extra_data then
      local x = player:getHandcardNum() - player.maxHp
      if x == 0 then return end

      if x > 0 then
        room:askToDiscard(player, {
          min_num = x,
          max_num = x,
          include_equip = false,
          skill_name = skillName,
          cancelable = false,
        })
      else
        player:drawCards(-x, skillName)
      end
    end
  end,
}

funing:addEffect(fk.Damaged, spec)
funing:addEffect(fk.HpLost, spec)
funing:addEffect(fk.HpRecover, spec)

return funing
