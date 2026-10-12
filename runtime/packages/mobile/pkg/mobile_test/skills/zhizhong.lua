
local zhizhong = fk.CreateSkill {
  name = "zhizhong",
}

Fk:loadTranslationTable{
  ["zhizhong"] = "置重",
  [":zhizhong"] = "出牌阶段限一次，你可以观看所有其他角色的手牌，选择并获得这些牌中点数和小于等于你手牌的牌，"..
  "然后你弃置X张牌（X为本次获得牌与原手牌的点数和之差）。",

  ["#zhizhong"] = "置重：观看所有其他角色的手牌，获得其中点数之和不大于你手牌点数的牌",
  ["#zhizhong-prey"] = "置重：获得其中点数之和不大于%arg的牌（当前和为%arg2）",

  ["$zhizhong1"] = "尝闻古人亦有此事，吾可依之解矣。",
  ["$zhizhong2"] = "虽涉世未深，吾亦有所思也!",
  ["$zhizhong3"] = "治学之要，贵在处事也！",
}

Fk:addPoxiMethod{
  name = zhizhong.name,
  prompt = function (data, extra_data, selected)
    local n = 0
    for _, id in ipairs(selected) do
      n = n + Fk:getCardById(id).number
    end
    return "#zhizhong-prey:::"..math.floor(extra_data.n) .. ":" .. n
  end,
  card_filter = function(to_select, selected, data, extra_data)
    local n = Fk:getCardById(to_select).number
    for _, id in ipairs(selected) do
      n = n + Fk:getCardById(id).number
    end
    return n <= extra_data.n
  end,
  feasible = Util.TrueFunc,
}

zhizhong:addEffect("active", {
  anim_type = "control",
  prompt = "#zhizhong",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(zhizhong.name, Player.HistoryPhase) == 0 and
      table.find(Fk:currentRoom().alive_players, function (p)
        return not p:isKongcheng() and p ~= player
      end)
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local card_data = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not p:isKongcheng() then
        table.insert(card_data, { p:toLogString(), p:getCardIds("h") })
      end
    end
    local n = 0
    for _, id in ipairs(player:getCardIds("h")) do
      n = n + Fk:getCardById(id).number
    end
    local result = room:askToPoxi(player, {
      poxi_type = zhizhong.name,
      data = card_data,
      cancelable = true,
      extra_data = {
        n = n,
      }
    })
    if #result > 0 then
      for _, id in ipairs(result) do
        n = n - Fk:getCardById(id).number
      end
      room:moveCardTo(result, Card.PlayerHand, player, fk.ReasonPrey, zhizhong.name, nil, false, player)
    end
    if n > 0 and not player.dead then
      room:askToDiscard(player, {
        min_num = n,
        max_num = n,
        include_equip = true,
        skill_name = zhizhong.name,
        cancelable = false,
      })
    end
  end,
})

return zhizhong
