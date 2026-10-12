local gongzhi = fk.CreateSkill{
  name = "heg__gongzhi",
}

Fk:loadTranslationTable{
  ["heg__gongzhi"] = "共执",
  [":heg__gongzhi"] = "你可以跳过摸牌阶段，令势力与你相同的角色依次摸一张牌，直到共计摸四张牌。",

  ["#heg__gongzhi-invoke"] = "共执：是否跳过摸牌阶段，令势力与你相同的角色摸共计四张牌？",
}

local H = require "packages.hegemony.util"

gongzhi:addEffect(fk.EventPhaseChanging, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(gongzhi.name) and
      data.phase == Player.Draw and not data.skipped
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = gongzhi.name,
      prompt = "#heg__gongzhi-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    data.skipped = true
    local n = 0
    local to = player
    while n < 4 do
      n = n + 1
      to:drawCards(1, gongzhi.name)
      local loop_lock = 0
      while true do
        to = to:getNextAlive()
        if H.compareKingdomWith(player, to, false) then
          break
        end
        loop_lock = loop_lock + 1
        if loop_lock > 20 then
          return
        end
      end
    end
  end,
})

gongzhi:addTest(function(room, me)
  local comp2 = room.players[2]
end)

return gongzhi

