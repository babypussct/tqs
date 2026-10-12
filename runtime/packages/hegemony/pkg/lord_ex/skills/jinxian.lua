local jinxian = fk.CreateSkill {
  name = "ld__jinxian",
}

Fk:loadTranslationTable {
  ["ld__jinxian"] = "近陷",
  [":ld__jinxian"] = "当你明置此武将牌后，你令所有你计算距离不大于1的角色执行：若其武将牌均明置，暗置一张武将牌；否则其弃置两张牌。",

  ["$ld__jinxian1"] = "如此荒辈之徒为主，成何用也。",
  ["$ld__jinxian2"] = "公既如此，恕在下诚难留之。",
}

local H = require "packages.hegemony.util"

jinxian:addEffect(fk.GeneralRevealed, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player == target and player:hasSkill(jinxian.name) then
      for _, v in pairs(data) do
        if table.contains(Fk.generals[v]:getSkillNameList(), jinxian.name) then return true end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players,
      function(p) return player:distanceTo(p) <= 1 and player:distanceTo(p) >= 0 end)
    room:sortByAction(targets)
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
