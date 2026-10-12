local fengying = fk.CreateSkill{
  name = "ld__fengying",
  tags = {Skill.Limited},
}
local H = require "packages.hegemony.util"
fengying:addEffect("active", {
  anim_type = "support",
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  can_use = function(self, player)
    return player:usedSkillTimes(fengying.name, Player.HistoryGame) == 0 and
      not player:isKongcheng() and not player:prohibitUse(Fk:cloneCard("threaten_emperor"))
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:useVirtualCard("threaten_emperor", player:getCardIds("h"), player, player, fengying.name)
    local targets = table.map(table.filter(room.alive_players, function(p) return H.compareKingdomWith(p, player) end), Util.IdMapper)
    if #targets > 0 then
      for _, pid in ipairs(targets) do
        local p = room:getPlayerById(pid)
        if not p.dead then
          p:drawCards(math.max(0, p.maxHp - p:getHandcardNum()), fengying.name)
        end
      end
    end
  end,
})

Fk:loadTranslationTable{
  ["ld__fengying"] = "奉迎",
  [":ld__fengying"] = "限定技，出牌阶段，你可将所有手牌当【挟天子以令诸侯】（无视大势力限制）使用，然后所有与你势力相同的角色将手牌补至其体力上限。",
  ["$ld__fengying1"] = "二臣恭奉，以迎皇嗣。",
  ["$ld__fengying2"] = "奉旨典选，以迎忠良。",
}

return fengying
