local huibian = fk.CreateSkill {
  name = "huibian",
}

Fk:loadTranslationTable {
  ["huibian"] = "挥鞭",
  [":huibian"] = "出牌阶段限一次，你可选择一名魏势力角色和另一名已受伤的魏势力角色，若如此做，你对前者造成1点伤害，令其摸两张牌，然后后者回复1点体力。",
  ["#huibian-prompt"] = "挥鞭：你选择一名魏势力角色和另一名已受伤的魏势力角色",

  ["huibian_tip_1"] = "受到伤害",
  ["huibian_tip_2"] = "回复体力",

  ["$huibian1"] = "吾任天下之智力，以道御之，无所不可。",
  ["$huibian2"] = "青青子衿，悠悠我心，但为君故，沉吟至今。",
}

local H = require "packages.hegemony.util"

huibian:addEffect("active", {
  anim_type = "control",
  target_num = 2,
  card_num = 0,
  prompt = "#huibian-prompt",
  can_use = function(self, player)
    return player:usedSkillTimes(huibian.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected == 0 then
      local target2 = to_select
      return H.getKingdom(target2) == "wei"
    elseif #selected == 1 then
      local target1 = to_select
      return H.getKingdom(target1) == "wei" and target1:isWounded()
    else
      return false
    end
  end,
  target_tip = function(self, player, to_select, selected, _, _, selectable, _)
    if not selectable then return end
    if #selected == 0 or (#selected > 0 and selected[1] == to_select) then
      return "huibian_tip_1"
    else
      return "huibian_tip_2"
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target1 = effect.tos[1]
    local target2 = effect.tos[2]
    room:damage {
      from = player,
      to = target1,
      damage = 1,
      skillName = huibian.name,
    }
    if not target1.dead then
      target1:drawCards(2, huibian.name)
    end
    if not target2.dead and target2:isWounded() then
      room:recover {
        who = target2,
        num = 1,
        recoverBy = player,
        skillName = huibian.name
      }
    end
  end,
})

return huibian
