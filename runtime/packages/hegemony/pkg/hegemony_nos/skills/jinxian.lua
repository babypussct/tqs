
local jinxian = fk.CreateSkill {
  name = "nos_heg__jinxian",
}

Fk:loadTranslationTable {
  ["nos_heg__jinxian"] = "近陷",
  [":nos_heg__jinxian"] = "当你明置此武将牌后，你令距离1以内的所有角色各执行此效果：若其武将牌均明置，则其暗置一张武将牌，否则其弃置两张牌。",

  ["$nos_heg__jinxian1"] = "如此荒辈之徒为主，成何用也。",
  ["$nos_heg__jinxian2"] = "公既如此，恕在下诚难留之。",
}

local H = require "packages.hegemony.util"

jinxian:addEffect(fk.GeneralRevealed, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(jinxian.name) then
      for _, v in pairs(data) do
        if table.contains(Fk.generals[v]:getSkillNameList(), jinxian.name) then
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getAlivePlayers(), function(p)
      return player:compareDistance(p, 1, "<=")
    end)
    for _, p in ipairs(targets) do
      if not p.dead then
        if H.allGeneralsRevealed(p) then
          H.doHideGeneral(room, p, p, jinxian.name)
        else
          room:askToDiscard(p, {
            min_num = 2,
            max_num = 2,
            include_equip = true,
            skill_name = jinxian.name,
            cancelable = false,
          })
        end
      end
    end
  end,
})

return jinxian
