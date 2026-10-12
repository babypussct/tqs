local lianji = fk.CreateSkill{
  name = "mobile__lianji",
}

Fk:loadTranslationTable{
  ["mobile__lianji"] = "连计",
  [":mobile__lianji"] = "出牌阶段限一次，你可以选择两名角色，第一名角色随机使用牌堆中的一张武器牌，然后视为对第二名角色随机使用以下一张牌："..
  "【杀】【决斗】【火攻】【南蛮入侵】【万箭齐发】，若对目标角色造成伤害，你获得等量的“连计”标记。",

  ["#mobile__lianji0"] = "连计：选择两名角色，第一名角色使用随机一张武器，然后视为对第二名角色使用随机伤害牌",
  ["#mobile__lianji1"] = "连计：%src 使用随机一张武器，然后视为对另一名角色使用随机伤害牌",
  ["#mobile__lianji2"] = "连计：%src 使用随机一张武器，然后视为对 %dest 使用随机伤害牌",
  ["@mobile__lianji"] = "连计",

  ["$mobile__lianji1"] = "计行周密，定无疏失。",
  ["$mobile__lianji2"] = "古有二桃杀三士，今以双计除虎狼。",
}

lianji:addEffect("active", {
  anim_type = "control",
  prompt = function (self, player, selected_cards, selected_targets)
    if #selected_targets == 0 then
      return "#mobile__lianji0"
    elseif #selected_targets == 1 then
      return "#mobile__lianji1:"..selected_targets[1].id
    elseif #selected_targets == 2 then
      return "#mobile__lianji2:"..selected_targets[1].id..":"..selected_targets[2].id
    end
  end,
  card_num = 0,
  target_num = 2,
  can_use = function(self, player)
    return player:usedSkillTimes(lianji.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected < 2
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local to = effect.tos[2]
    local cards = table.filter(room.draw_pile, function(id)
      return Fk:getCardById(id).sub_type == Card.SubtypeWeapon and
        target:canUseTo(Fk:getCardById(id), target)
    end)
    if #cards > 0 then
      local card = Fk:getCardById(room:tableRandomPick(cards))
      if card.name == "qinggang_sword" then
        room:moveCardTo(card, Card.Void, nil, fk.ReasonJustMove, lianji.name)
        card = room:printCard("seven_stars_sword", Card.Spade, 6)
      end
      if target:canUseTo(card, target) then
        room:useCard{
          from = target,
          tos = {target},
          card = card,
        }
      end
    end
    if target.dead or to.dead then return end
    local names = table.filter({"slash", "duel", "fire_attack", "savage_assault", "archery_attack"}, function (name)
      local card = Fk:cloneCard(name)
      card.skillName = lianji.name
      return target:canUseTo(card, to, {bypass_distances = true, bypass_times = true})
    end)
    if #names == 0 then return end
    local use = room:useVirtualCard(room:tableRandomPick(names), nil, target, to, lianji.name, true)
    if use and use.damageDealt and use.damageDealt[to] and not player.dead then
      room:addPlayerMark(player, "@mobile__lianji", use.damageDealt[to])
    end
  end,
})

lianji:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@mobile__lianji", 0)
end)

return lianji
