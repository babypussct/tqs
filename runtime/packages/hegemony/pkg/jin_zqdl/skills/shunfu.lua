
local shunfu = fk.CreateSkill{
  name = "heg__shunfu",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["heg__shunfu"] = "瞬覆",
  [":heg__shunfu"] = "限定技，出牌阶段，你可以令至多三名未确定势力的其他角色各摸两张牌，然后这些角色依次可以使用一张【杀】（无距离限制且不可被响应）。",

  ["#heg__shunfu"] = "瞬覆：令至多三名未确定势力的角色各摸两张牌且可以使用一张【杀】",
  ["#heg__shunfu-slash"] = "瞬覆：你可以使用一张无距离限制且不可被响应的【杀】",

  ["$heg__shunfu1"] = "烈士雄心，志存高远。",
  ["$heg__shunfu2"] = "乱世之中，唯我司马！",
}

shunfu:addEffect("active", {
  anim_type = "offensive",
  prompt = "#heg__shunfu",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 3,
  can_use = function(self, player)
    return player:usedSkillTimes(shunfu.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected, selected_cards)
    return to_select ~= player and to_select.kingdom == "unknown"
  end,
  on_use = function(self, room, effect)
    local targets = table.simpleClone(effect.tos)
    room:sortByAction(targets)
    for _, p in ipairs(targets) do
      if not p.dead then
        p:drawCards(2, shunfu.name)
      end
    end
    for _, p in ipairs(targets) do
      if not p.dead then
        local use = room:askToUseCard(p, {
          skill_name = shunfu.name,
          pattern = "slash",
          prompt = "#heg__shunfu-slash",
          cancelable = true,
          extra_data = {
            bypass_distances = true,
            bypass_times = true,
          },
        })
        if use then
          use.extraUse = true
          use.disresponsiveList = table.simpleClone(room.players)
          room:useCard(use)
        end
      end
    end
  end,
})

return shunfu
