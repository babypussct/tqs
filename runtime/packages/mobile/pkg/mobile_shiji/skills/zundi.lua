local zundi = fk.CreateSkill {
  name = "zundi",
}

Fk:loadTranslationTable{
  ["zundi"] = "尊嫡",
  [":zundi"] = "出牌阶段限一次，你可以弃置一张手牌并选择一名角色，然后你进行判定，若结果为：黑色，其摸三张牌；红色，其可以移动场上一张牌。",

  ["#zundi"] = "尊嫡：弃一张手牌指定一名角色，你判定，黑色其摸三张牌，红色则其可以移动场上一张牌",
  ["#zundi-move"] = "尊嫡：你可以移动场上一张牌",

  ["$zundi1"] = "盖闻春秋之义，立子自当立长。",
  ["$zundi2"] = "五官将才德兼备，是以宜承正统。",
}

zundi:addEffect("active", {
  anim_type = "support",
  prompt = "#zundi",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(zundi.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getCardIds("h"), to_select) and not player:prohibitDiscard(to_select)
  end,
  target_filter = function(self, player, to_select, selected, cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:throwCard(effect.cards, zundi.name, player, player)
    if player.dead then return end
    local judge = {
      who = player,
      reason = zundi.name,
      pattern = {
        [".|.|black,red"] = "good",
        [".|.|red"] = "red",
        [".|.|black"] = "black",
        ["else"] = "bad",
      },
    }
    room:judge(judge)
    if not judge.results or target.dead then return false end
    if target.dead then return end
    if table.contains(judge.results, "black") then
      target:drawCards(3, zundi.name)
    elseif table.contains(judge.results, "red") and #room:canMoveCardInBoard() > 0 then
      local targets = room:askToChooseToMoveCardInBoard(target, {
        prompt = "#zundi-move",
        skill_name = zundi.name,
        cancelable = true,
      })
      if #targets == 2 then
        room:askToMoveCardInBoard(target, {
          target_one = targets[1],
          target_two = targets[2],
          skill_name = zundi.name,
        })
      end
    end
  end,
})

return zundi
