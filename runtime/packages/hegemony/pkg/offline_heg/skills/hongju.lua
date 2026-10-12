local hongju = fk.CreateSkill {
  name = "ofl_heg__hongju",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable {
  ["ofl_heg__hongju"] = "鸿举",
  [":ofl_heg__hongju"] = "限定技，出牌阶段，你可以选择一名其他角色，然后你对除其以外的角色依次发起一次“军令”（你必须执行）。"..
  "不执行的角色本回合移出游戏。",

  ["#ofl_heg__hongju"] = "鸿举：选择一名角色，除其以外的角色执行军令，不执行者本回合移出游戏",

  ["$ofl_heg__hongju1"] = "一举拿下，鸿途可得。",
  ["$ofl_heg__hongju2"] = "鸿飞荣升，举重若轻。",
}

local H = require "packages.hegemony.util"

hongju:addEffect("active", {
  anim_type = "control",
  prompt = "#ofl_heg__hongju",
  can_use = function(self, player)
    return player:usedSkillTimes(hongju.name, Player.HistoryGame) == 0
  end,
  card_num = 0,
  target_num = 1,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    for _, p in ipairs(room:getOtherPlayers(target)) do
      if not p.dead and
        not H.askToCommand(player, {
          tos = { p },
          skill_name = hongju.name,
          forced = p == player,
        }) then
        room:setPlayerMark(p, "@@lure_tiger-turn", 1)
      end
    end
  end,
})

return hongju
