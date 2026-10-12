
local yaowu = fk.CreateSkill{
  name = "m_heg__yaowu",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["m_heg__yaowu"] = "耀武",
  [":m_heg__yaowu"] = "限定技，当你造成伤害后，你可以明置此武将牌，加2点体力上限，回复2点体力，修改〖恃勇〗，"..
  "且当你死亡后，与你势力相同的角色各失去1点体力。",

  ["$m_heg__yaowu1"] = "俞涉小儿，岂是我的对手！",
  ["$m_heg__yaowu2"] = "上将潘凤？哼！还不是死在我刀下！",
}

local H = require "packages.hegemony.util"

yaowu:addEffect(fk.Damage, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yaowu.name) and
      player:usedSkillTimes(yaowu.name, Player.HistoryGame) == 0 and player:isFakeSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "m_heg__yaowu-noclear", 1)
    room:changeMaxHp(player, 2)
    if not player.dead then
      room:recover{
        who = player,
        num = 2,
        recoverBy = player,
        skillName = yaowu.name,
      }
    end
  end,
})

yaowu:addEffect(fk.Deathed, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("m_heg__yaowu-noclear") > 0 and
      table.find(player.room.alive_players, function(p)
        return H.compareKingdomWith(p, player)
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      if not p.dead and H.compareKingdomWith(p, player) then
        room:loseHp(p, 1, yaowu.name)
      end
    end
  end,
})

return yaowu
