
local chuchong = fk.CreateSkill {
  name = "heg__chuchong",
}

Fk:loadTranslationTable {
  ["heg__chuchong"] = "除虫",
  [":heg__chuchong"] = "你杀死同势力角色的奖惩改为所有同势力角色依次：回复所有体力、手牌摸至五张、可以变更一次副将。",
}

local H = require "packages.hegemony.util"

chuchong:addEffect(fk.BuryVictim, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(chuchong.name) and
      data.killer == player and H.compareKingdomWith(player, target)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local deathEvent = room.logic:getCurrentEvent():findParent(GameEvent.Death, true).data
    deathEvent.extra_data = deathEvent.extra_data or {}
    deathEvent.extra_data.ignorePunishment = true
    for _, p in ipairs(room:getAlivePlayers()) do
      if not p.dead and H.compareKingdomWith(player, p) then
        if p:isWounded() then
          room:recover{
            who = p,
            num = p:getLostHp(),
            recoverBy = p,
            skillName = "kill",
          }
        end
        if not p.dead and p:getHandcardNum() < 5 then
          p:drawCards(5 - p:getHandcardNum(), "kill")
        end
        if not p.dead then
          if room:askToChoice(player, {
            choices = { "transformDeputy", "Cancel" },
            skill_name = chuchong.name,
          }) ~= "Cancel" then
            H.transformGeneral(room, p)
          end
        end
      end
    end
  end,
})

return chuchong
