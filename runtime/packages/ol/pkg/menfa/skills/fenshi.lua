
local fenshi = fk.CreateSkill {
  name = "fenshi",
  tags = { Skill.Family },
}

Fk:loadTranslationTable{
  ["fenshi"] = "纷势",
  [":fenshi"] = "宗族技，每回合限一次，若有同族角色手牌数等于势力数，你的锦囊牌可以额外结算一次。",

  ["#fenshi-invoke"] = "纷势：你可以令%arg额外结算一次",
}

local U = require "packages.utility.utility"

fenshi:addEffect(fk.CardUsing, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(fenshi.name) and
      data.card:isCommonTrick() and #data.tos > 0 and
      player:usedSkillTimes(fenshi.name, Player.HistoryTurn) == 0 then
      local kingdoms = {}
      for _, p in ipairs(player.room.alive_players) do
        table.insertIfNeed(kingdoms, p.kingdom)
      end
      return table.find(player.room.alive_players, function (p)
        return U.FamilyMember(player, p) and p:getHandcardNum() == #kingdoms
      end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = fenshi.name,
      prompt = "#fenshi-invoke:::" .. data.card:toLogString(),
    })
  end,
  on_use = function(self, event, target, player, data)
    data.additionalEffect = (data.additionalEffect or 0) + 1
  end,
})

return fenshi
