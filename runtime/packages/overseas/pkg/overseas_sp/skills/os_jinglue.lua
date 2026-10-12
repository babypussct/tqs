local osJinglue = fk.CreateSkill {
  name = "os__jinglue"
}

Fk:loadTranslationTable{
  ["os__jinglue"] = "景略",
  [":os__jinglue"] = "出牌阶段限一次，若场上没有“死士”牌，你可观看一名其他角色的手牌，将其中一张牌标记为“死士”。" ..
  "当“死士”牌被其使用时，你令此牌无效；其回合结束时，若“死士”牌在牌堆、弃牌堆或任意角色的区域内，你获得之。",

  ["#os__jinglue"] = "景略:观看一名其他角色的手牌，将其中一张牌标记为“死士”",
  ["#CardNullifiedBySkill"] = "由于 %arg 的效果，%from 使用的 %arg2 无效",

  ["$os__jinglue1"] = "安待良机，自有舍身报吾之士。",
  ["$os__jinglue2"] = "察局备间，保诸事不虞。",
}

-- 主动技能
osJinglue:addEffect("active", {
  name = "os__jinglue",
  anim_type = "control",
  prompt = "#os__jinglue",
  times = function (self, player)
    return 1 - player:usedSkillTimes(osJinglue.name, Player.HistoryPhase)
  end,
  can_use = function(self, player)
    return
      player:usedSkillTimes(osJinglue.name, Player.HistoryPhase) < 1 and
      table.every(Fk:currentRoom().alive_players, function(p)
        return table.every(p:getCardIds("ej"), function(id)
          return Fk:getCardById(id):getMark("_os__sishi") == 0
        end)
      end)
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 1,
  target_filter = function(self, player, to_select, selected)
    return #selected < 1 and to_select ~= player and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local cid = room:askToChooseCard(
      player,
      {
        target = target,
        flag = { card_data = { { "$Hand", target:getCardIds("h") } } },
        skill_name = osJinglue.name
      }
    )
    room:setCardMark(Fk:getCardById(cid), "_os__sishi", { target.id, player.id })
    local mark_name = "_os__jinglue_now-" .. tostring(player.id)
    room:addTableMarkIfNeed(target, mark_name, cid)
    room:addTableMarkIfNeed(player, "_os__jinglue", target.id)
  end,
})

-- 触发技能
osJinglue:addEffect(fk.CardUsing, {
  is_delay_effect = true,
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    local mark
    for _, id in ipairs(Card:getIdList(data.card)) do
      if Fk:getCardById(id):getMark("_os__sishi") ~= 0 then
        if not mark then
          mark = Fk:getCardById(id):getMark("_os__sishi")
        elseif mark ~= Fk:getCardById(id):getMark("_os__sishi") then
          return false
        end
      else
        return false
      end
    end
    return mark and mark[1] == target.id and mark[2] == player.id
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, { tos = {target} })
    return true
  end,
  on_use = function(self, event, target, player, data)
    data:setNullified()
  end,
})

osJinglue:addEffect(fk.TurnEnd, {
  is_delay_effect = true,
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target:getMark("_os__jinglue_now-" .. player.id) ~= 0 and player:isAlive() then
      for _, id in ipairs(target:getMark("_os__jinglue_now-" .. player.id)) do
        if
          table.contains(
            { Card.DrawPile, Card.DiscardPile, Card.PlayerHand, Card.PlayerEquip, Card.PlayerJudge },
            player.room:getCardArea(id)
          )
        then
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    local mark = target:getMark("_os__jinglue_now-" .. player.id)
    for i = #mark, 1, -1 do
      local id = mark[i]
      if
        table.contains(
          { Card.DrawPile, Card.DiscardPile, Card.PlayerHand, Card.PlayerEquip, Card.PlayerJudge },
          room:getCardArea(id)
        )
      then
        table.remove(mark, i)
        room:setCardMark(Fk:getCardById(id), "_os__sishi", 0)
        table.insert(cards, id)
      end
    end
    room:setPlayerMark(target, "_os__jinglue_now-" .. player.id, mark)
    room:obtainCard(player, cards, true, fk.ReasonPrey, player, osJinglue.name)
  end,
})

return osJinglue
