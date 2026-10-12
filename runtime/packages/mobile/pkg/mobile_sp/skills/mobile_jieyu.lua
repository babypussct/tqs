local mobileJieyu = fk.CreateSkill {
  name = "mobile__jieyu",
}

Fk:loadTranslationTable{
  ["mobile__jieyu"] = "竭御",
  [":mobile__jieyu"] = "结束阶段，你可从弃牌堆中随机获得X张牌名各不相同的基本牌（X为3-你上次发动此技能至本阶段，" ..
  "你成为其他角色【杀】或伤害类锦囊目标的次数，X至少为1）。",
  ["@mobile__jieyu"] = "竭御",

  ["$mobile__jieyu1"] = "既事使君，峻自不负重任！",
  ["$mobile__jieyu2"] = "吾头可得，城不可得！",
}

mobileJieyu:addEffect(fk.EventPhaseStart, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(mobileJieyu.name) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = player:getMark("@mobile__jieyu")
    local names, get = {}, {}
    local pile = table.simpleClone(room.discard_pile)
    while #get < x and #pile > 0 do
      local id = table.remove(pile, math.random(#pile))
      local card = Fk:getCardById(id)
      if card.type == Card.TypeBasic and table.insertIfNeed(names, card.trueName) then
        table.insert(get, id)
      end
    end
    if #get > 0 then
      room:obtainCard(player, get, true, fk.ReasonPrey, player, mobileJieyu.name)
    end
  end,
})

mobileJieyu:addEffect(fk.EventPhaseEnd, {
  can_refresh = function (self, event, target, player, data)
    return
      target == player and
      player:getMark("@mobile__jieyu") > 0 and
      player.phase == Player.Finish and
      player:getMark("@mobile__jieyu") ~= 3
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@mobile__jieyu", 3)
  end,
})

mobileJieyu:addEffect(fk.TargetConfirmed, {
  can_refresh = function (self, event, target, player, data)
    return
      target == player and
      player:getMark("@mobile__jieyu") > 0 and
      (
        data.card.trueName == "slash" or
        (data.card.is_damage_card and data.card.type == Card.TypeTrick)
      ) and
      data.from ~= player and
      player:getMark("@mobile__jieyu") > 1 and
      player:usedSkillTimes(mobileJieyu.name, Player.HistoryGame) > 0 -- 未发动第一次技能时不会使X减少
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:removePlayerMark(player, "@mobile__jieyu", 1)
  end,
})

mobileJieyu:addAcquireEffect(function(self, player)
  player.room:setPlayerMark(player, "@mobile__jieyu", 3)
end)

mobileJieyu:addLoseEffect(function(self, player)
  player.room:setPlayerMark(player, "@mobile__jieyu", 0)
end)

return mobileJieyu
