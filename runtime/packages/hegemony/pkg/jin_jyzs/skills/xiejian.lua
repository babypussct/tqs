local xiejian = fk.CreateSkill {
    name = "heg__xiejian",
}

Fk:loadTranslationTable {
    ["heg__xiejian"] = "挟奸",
    [":heg__xiejian"] = "出牌阶段限一次，你可以对一名其他角色发起“军令”，且你以此法抽取的备选“军令”对其他角色不可见，若其不执行，其强制执行你抽取的备选“军令”。",

    ["#heg__xiejian"] = "挟奸：选择一名其他角色发起“军令”",
}

local H = require "packages.hegemony.util"

xiejian:addEffect("active", {
  anim_type = "offensive",
  prompt = "#heg__xiejian",
  can_use = function(self, player)
    return player:usedSkillTimes(xiejian.name, Player.HistoryPhase) == 0
  end,
  target_num = 1,
  card_num = 0,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local to = effect.tos[1]
    local choice, commands = H.askToStartCommand(player, {
      skill_name = xiejian.name,
      no_log = true,
    })
    table.removeOne(commands, choice)
    if player.dead or to.dead or not choice then return false end
    room:sendLog {
        type = "#AskCommandTo",
        from = player.id,
        to = { to.id },
        arg = xiejian.name,
        toast = true,
    }
    if not H.Command({
      tos = { to },
      skillName = xiejian.name,
      command = choice,
      from = player,
      forced = false,
    }) then
      H.Command({
        tos = { to },
        skillName = xiejian.name,
        command = commands[1],
        from = player,
        forced = true,
      })
    end
  end,
})

return xiejian
