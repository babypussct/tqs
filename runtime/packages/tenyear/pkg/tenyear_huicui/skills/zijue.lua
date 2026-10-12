local zijue = fk.CreateSkill {
  name = "zijue",
}

Fk:loadTranslationTable{
  ["zijue"] = "赀爵",
  [":zijue"] = "出牌阶段限一次，你可以令一名其他角色声明2~4之间的一个数字，你可以交给其X张牌并回复1点体力，"..
  "然后直到你的下个回合开始：其他角色与你计算距离+X，你的拼点牌点数+X且拼点后摸一张牌；若你未交给其牌则你摸X张牌（X为其声明的数字）。",

  ["#zijue-active"] = "赀爵：令一名其他角色声明2~4，你可以交给其此数字的牌获得增益或改为摸牌",
  ["#zijue-choose"] = "赀爵：请声明2~4的数字，%src 可以交给你此数字的牌获得增益或改为摸牌",
  ["#zijue-give"] = "赀爵：你可以交给 %dest %arg张牌获得增益，或点“取消”摸%arg张牌",
  ["@zijue"] = "赀爵",

  ["$zijue1"] = "恨朱紫有价，怨寒门无阶。",
  ["$zijue2"] = "吾一腔才学，不当五百万钱否？",
}

zijue:addEffect("active", {
  prompt = "#zijue-active",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(zijue.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = zijue.name
    local from = effect.from
    local to = effect.tos[1]
    local number = room:askToNumber(to, {
      min = 2,
      max = 4,
      skill_name = skillName,
      cancelable = false,
      prompt = "#zijue-choose:" .. from.id,
    })
    ---@cast number integer
    local ids = room:askToCards(from, {
      min_num = number,
      max_num = number,
      include_equip = true,
      skill_name = skillName,
      prompt = "#zijue-give::" .. to.id .. ":" .. number,
    })

    if #ids == number then
      room:obtainCard(to, ids, false, fk.ReasonGive, from, skillName)
      if not from.dead then
        room:recover{
          who = from,
          num = 1,
          recoverBy = from,
          skillName = skillName,
        }
      end

      room:setPlayerMark(from, "@zijue", number)
    else
      from:drawCards(number, skillName)
    end
  end,
})

zijue:addEffect("distance", {
  correct_func = function(self, from, to)
    return to:getMark("@zijue")
  end,
})

zijue:addEffect(fk.PindianCardsDisplayed, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return (data.from == player or table.contains(data.tos, player)) and
      player:getMark("@zijue") > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:changePindianNumber(data, player, player:getMark("@zijue"), zijue.name)
  end,
})

zijue:addEffect(fk.PindianResultConfirmed, {
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@zijue") > 0 and
      (data.from == player or data.to == player)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, zijue.name)
  end,
})

zijue:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@zijue", 0)
  end,
})

return zijue
