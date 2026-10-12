local dianhu = fk.CreateSkill{
  name = "ofl_heg__dianhu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ofl_heg__dianhu"] = "点虎",
  [":ofl_heg__dianhu"] = "锁定技，当你首次明置此武将牌后，你指定一名其他角色；与你势力相同的角色对其造成伤害后，伤害来源摸一张牌。",

  ["@@ofl_heg__dianhu"] = "点虎",
  ["#ofl_heg__dianhu-choose"] = "点虎：指定一名角色，与你势力相同的角色对其造成伤害后，伤害来源摸一张牌",

  ["$ofl_heg__dianhu1"] = "预则立，不预则废！",
  ["$ofl_heg__dianhu2"] = "就用你，给我军祭旗！",
}

local H = require "packages.hegemony.util"

dianhu:addEffect(fk.Damage, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(dianhu.name) and
      table.contains(player:getTableMark(dianhu.name), data.to.id) and
      target and not target.dead and H.compareKingdomWith(target, player)
  end,
  on_use = function(self, event, target, player, data)
    target:drawCards(1, dianhu.name)
  end,
})

dianhu:addEffect(fk.GeneralRevealed, {
  can_trigger = function (self, event, target, player, data)
    if target == player and player:hasSkill(dianhu.name) and player:usedEffectTimes(self.name, Player.HistoryGame) == 0 then
      for _, v in pairs(data) do
        if table.contains(Fk.generals[v]:getSkillNameList(), dianhu.name) then return true end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if #room:getOtherPlayers(player, false) > 0 then
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = room:getOtherPlayers(player, false),
        skill_name = dianhu.name,
        prompt = "#ofl_heg__dianhu-choose",
        cancelable = false,
      })[1]
      room:addTableMark(to, "@@ofl_heg__dianhu", player.id)
      room:addTableMarkIfNeed(player, dianhu.name, to.id)
    end
  end,
})

dianhu:addLoseEffect(function (self, player, is_death)
  if is_death and player:getMark(dianhu.name) ~= 0 then
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      room:removeTableMark(p, "@@ofl_heg__dianhu", player.id)
    end
  end
end)

return dianhu
