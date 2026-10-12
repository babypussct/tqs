local skill = fk.CreateSkill {
  name = "sishiling_other&",
}

Fk:loadTranslationTable {
  ["sishiling_other&"] = "死士令",
  [":sishiling_other&"] = "每轮限一次，所有本轮明置过武将牌的晋势力角色可以移除其副将的武将牌并发动以下一个未以此法发动过的技能：“瞬覆”，“奉迎”，“将略”，“勇进”和“乱武”。",

  ["#sishiling-choose"] = "死士令：移除你的副将并发动一个未以此法发动的技能",
}

local H = require "packages.hegemony.util"
local U = require "packages.utility.utility"

skill:addEffect("active", {
  anim_type = "special",
  can_use = function(self, player)
    local targets = Fk:currentRoom().players
    return table.every(targets,
          function(p) return p:usedSkillTimes(skill.name, Player.HistoryRound) == 0 and
            p:usedSkillTimes(skill.name, Player.HistoryGame) < 6 end)
        and H.hasHegLordSkill(Fk:currentRoom(), player, "heg__jiaping") and
        player:getMark("GeneralRevealed-round") > 0
        and player.deputyGeneral ~= "blank_shibing" and player.deputyGeneral ~= "blank_nvshibing"
  end,
  target_num = 0,
  card_num = 0,
  on_use = function(self, room, effect)
    local player = effect.from
    local skill_list = { "heg__shunfu", "ld__fengying", "jianglue", "yongjin", "luanwu" }
    local lord = table.filter(room.alive_players, function(p) return p:hasSkill("heg__jiaping") end)
    local skill_used = lord[1]:getTableMark("sishiling_used") or {}
    for _, s in ipairs(skill_used) do
      if table.contains(skill_list, s) then
        table.removeOne(skill_list, s)
      end
    end
    if #skill_list == 0 then return false end
    local result = U.askToChooseSkills(player, {
      skill_name = skill.name,
      skills = table.slice(skill_list, 1, #skill_list + 1),
      min_num = 0,
      prompt = "#sishiling-choose",
    })
    if result == "" then return false end
    local choice = result
    room:addTableMarkIfNeed(lord[1], "sishiling_used", choice[1])
    if #choice > 0 then
      H.removeGeneral(player, true)
      room:askToUseActiveSkill(player, {
        skill_name = choice[1],
        cancelable = false,
      })
    end
  end,
})

return skill
