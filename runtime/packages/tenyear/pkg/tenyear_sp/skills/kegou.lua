
local kegou = fk.CreateSkill{
  name = "kegou",
}

Fk:loadTranslationTable{
  ["kegou"] = "克构",
  [":kegou"] = "出牌阶段开始时或你使用或打出过牌的回合结束时，你可以与一名其他角色拼点，"..
  "若你赢，你获得牌堆中最小的两个点数的的牌各一张；若你没赢，其可以对你使用一张【杀】，然后你可以继续重复此流程。",

  ["#kegou-choose"] = "克构：与一名角色拼点，若赢你获得两张牌，若没赢其视为对你使用【杀】并可重复拼点流程",
  ["#kegou-slash"] = "克构：你可以对 %dest 使用【杀】",

  ["$kegou1"] = "",
  ["$kegou2"] = "",
}

local spec = {
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(player.room:getOtherPlayers(player, false), function(p)
      return player:canPindian(p)
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = kegou.name,
      prompt = "#kegou-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local pindian = player:pindian({ to }, kegou.name)
    if player.dead then return end
    if pindian.results[to].winner == player then
      if #room.draw_pile == 0 then return end
      local nums = { 100, 100 }
      for _, id in ipairs(room.draw_pile) do
        local n = Fk:getCardById(id).number
        if n <= nums[1] then
          nums[1] = n
        elseif n < nums[2] then
          nums[2] = n
        end
      end
      local cards = {}
      for i = #room.draw_pile, 1, -1 do
        if table.contains(nums, Fk:getCardById(room.draw_pile[i]).number) then
          table.insert(cards, room.draw_pile[i])
          if #cards == 2 then
            break
          end
        end
      end
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, kegou.name, nil, false, player)
    else
      if not to.dead then
        local use = room:askToUseCard(to, {
          skill_name = kegou.name,
          pattern = "slash",
          prompt = "#kegou-slash::" .. player.id,
          cancelable = true,
          extra_data = {
            exclusive_targets = { player.id },
            bypass_distances = true,
            bypass_times = true,
          }
        })
        if use then
          use.extraUse = true
          room:useCard(use)
        end
      end
      if not player:isKongcheng() and
        table.find(room:getOtherPlayers(player, false), function(p)
          return player:canPindian(p)
        end) then
        self:doCost(event, target, player, data)
      end
    end
  end,
}

kegou:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(kegou.name) and target.phase == Player.Play and
      not player:isKongcheng() and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return player:canPindian(p)
      end)
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

kegou:addEffect(fk.TurnEnd, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(kegou.name) and
      not player:isKongcheng() and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return player:canPindian(p)
      end) then
      if #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        return e.data.from == player
      end, Player.HistoryTurn) > 0 then
        return true
      end
      if #player.room.logic:getEventsOfScope(GameEvent.RespondCard, 1, function (e)
        return e.data.from == player
      end, Player.HistoryTurn) > 0 then
        return true
      end
    end
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

return kegou
