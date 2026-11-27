
local duwu = fk.CreateSkill {
  name = "nos_heg__duwu",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable {
  ["nos_heg__duwu"] = "黩武",
  [":nos_heg__duwu"] = "限定技，出牌阶段，你可以发起一次“军令”，令你攻击范围内所有与你势力不同或未确定势力的其他角色执行此“军令”，"..
  "若其不执行，则你对其造成1点伤害，然后你摸一张牌；所有“军令”结算结束后，若期间有角色进入濒死状态被救回，你失去1点体力。",

  ["#nos_heg__duwu"] = "黩武：令攻击范围内所有与你势力不同的角色执行“军令”！",

  ["$nos_heg__duwu1"] = "破曹大功，正在今朝！",
  ["$nos_heg__duwu2"] = "全力攻城！言退者，斩！",
}

local H = require "packages.hegemony.util"

duwu:addEffect("active", {
  anim_type = "offensive",
  prompt = "#nos_heg__duwu",
  can_use = function(self, player)
    return player:usedSkillTimes(duwu.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local command = H.askToStartCommand(player, {
      skill_name = duwu.name,
    })
    local targets = table.filter(room.alive_players, function(p)
      return H.compareKingdomWith(player, p, true) and player:inMyAttackRange(p)
    end)
    if #targets > 0 then
      room:doIndicate(player, targets)
      room:sortByAction(targets)
      local x = 0
      local events = room.logic.event_recorder[GameEvent.Dying]
      if events then
        x = #events
      end
      H.Command{
        from = player,
        tos = targets,
        command = command,
        skillName = duwu.name,
      }
      if not player.dead then
        events = room.logic.event_recorder[GameEvent.Dying]
        if events then
          for i = x + 1, #events, 1 do
            if not events[i].data.who.dead then
              room:loseHp(player, 1, duwu.name)
              break
            end
          end
        end
      end
    end
  end,
})

duwu:addEffect(H.CommandExecuted, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player == data.from and not target.dead and data.skillName == duwu.name and not data.succeed
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:damage {
      from = player,
      to = target,
      damage = 1,
      skillName = duwu.name,
    }
    if not player.dead then
      player:drawCards(1, duwu.name)
    end
  end
})

return duwu
