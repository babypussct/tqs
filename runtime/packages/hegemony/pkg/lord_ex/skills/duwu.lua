
local duwu = fk.CreateSkill {
  name = "ld__duwu",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable {
  ["ld__duwu"] = "黩武",
  [":ld__duwu"] = "限定技，出牌阶段，你可以失去1点体力，对你攻击范围内所有其他势力的角色发起一次“军令”，"..
  "若其中每有一名角色不执行，你对其造成1点伤害，然后你摸一张牌。",

  ["#ld__duwu"] = "黩武：失去1点体力，对攻击范围内所有其他势力的角色发起“军令”！",

  ["$ld__duwu1"] = "破曹大功，正在今朝！",
  ["$ld__duwu2"] = "全力攻城！言退者，斩！",
}

local H = require "packages.hegemony.util"

duwu:addEffect("active", {
  anim_type = "offensive",
  prompt = "#ld__duwu",
  can_use = function(self, player)
    return player:usedSkillTimes(duwu.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    room:loseHp(player, 1, duwu.name, player)
    if player.dead then return end
    local command = H.askToStartCommand(player, {
      skill_name = duwu.name,
    })
    local targets = table.filter(room.alive_players, function(p)
      return not H.compareKingdomWith(player, p) and H.getGeneralsRevealedNum(p) > 0 and player:inMyAttackRange(p)
    end)
    if #targets > 0 then
      room:doIndicate(player, targets)
      room:sortByAction(targets)
      H.Command{
        from = player,
        tos = targets,
        command = command,
        skillName = duwu.name,
      }
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
