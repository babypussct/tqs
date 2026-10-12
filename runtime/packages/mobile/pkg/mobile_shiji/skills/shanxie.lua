local shanxie = fk.CreateSkill {
  name = "shanxie",
}

Fk:loadTranslationTable{
  ["shanxie"] = "擅械",
  [":shanxie"] = "出牌阶段限一次，你可以从牌堆中获得一张武器牌（若没有，则随机获得一名其他角色装备区内的武器牌）。其他角色使用【闪】响应"..
  "你使用的【杀】时，若此【闪】没有点数或点数不大于你攻击范围的两倍，则此【闪】无效。",

  ["#shanxie"] = "擅械：你可以从牌堆获得一张武器牌（若没有则随机获得一名其他角色的武器）",

  ["$shanxie1"] = "快快取我兵器，我上阵杀敌！",
  ["$shanxie2"] = "哈哈！还是自己的兵器用着趁手！",
}

shanxie:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#shanxie",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedEffectTimes(shanxie.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local card = room:getCardsFromPileByRule(".|.|.|.|.|weapon")
    if #card == 0 then
      local ids = {}
      for _, p in ipairs(room:getOtherPlayers(player, false)) do
        if #p:getEquipments(Card.SubtypeWeapon) > 0 then
          table.insertTableIfNeed(ids, p:getEquipments(Card.SubtypeWeapon))
        end
      end
      card = {room:tableRandomPick(ids)}
    end
    if #card > 0 then
      room:obtainCard(player, card, true, fk.ReasonPrey, player, shanxie.name)
    end
  end,
})
shanxie:addEffect(fk.PreCardEffect, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shanxie.name) and data.card.name == "jink" and target ~= player and
      data.responseToEvent and data.responseToEvent.from == player and
      data.card.number <= 2 * player:getAttackRange()
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    data.nullified = true
  end,
})

return shanxie
