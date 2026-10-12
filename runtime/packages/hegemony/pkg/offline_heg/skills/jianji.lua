local jianji = fk.CreateSkill{
  name = "ofl_heg__jianji",
}

Fk:loadTranslationTable{
  ["ofl_heg__jianji"] = "谏计",
  [":ofl_heg__jianji"] = "出牌阶段限一次，你可以令一名其他角色摸一张牌并展示之，然后其可以使用此牌（可转化）。",

  ["#ofl_heg__jianji"] = "谏计：令一名其他角色摸一张牌，其可以使用之（可转化）",
  ["#ofl_heg__jianji-use"] = "谏计：你可以使用这张牌（可转化）",

  ["$ofl_heg__jianji1"] = "锦上添花，不如雪中送炭。",
  ["$ofl_heg__jianji2"] = "密计交于将军，可解燃眉之困。",
}

jianji:addEffect("active", {
  anim_type = "support",
  prompt = "#ofl_heg__jianji",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(jianji.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local target = effect.tos[1]
    local cards = target:drawCards(1, jianji.name)
    cards = table.filter(cards, function (id)
      return table.contains(target:getCardIds("h"), id)
    end)
    if #cards < 1 then return end
    local id = cards[1]
    target:showCards(id)
    if not target.dead and table.contains(target:getCardIds("h"), id) then
      local use = room:askToPlayCard(target, {
        cards = {id},
        skill_name = jianji.name,
        prompt = "#ofl_heg__jianji-use",
        cancelable = true,
        extra_data = {
          bypass_times = true,
          extraUse = true,
        },
        skip = true,
      })
      if use then
        use.extraUse = true
        room:useCard(use)
      end
    end
  end,
})

return jianji
