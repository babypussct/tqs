
local siling = fk.CreateSkill {
  name = "m_heg__siling",
}

Fk:loadTranslationTable{
  ["m_heg__siling"] = "肆凌",
  [":m_heg__siling"] = "出牌阶段限一次，你可以选择一名副将不是士兵的同势力角色并抽取一个国战限定技，令其选择是否发动，"..
  "若其发动，其将副将替换为士兵。你使用【杀】次数+X（X为场上存活士兵数）。",

  ["#m_heg__siling"] = "肆凌：令一名同势力角色抽取一个限定技，其可以发动并将副将替换为士兵",
  ["#m_heg__siling-invoke"] = "肆凌：是否将副将替换为士兵，发动“%arg”？",

  ["$m_heg__siling1"] = "尔等所过之城，当俱为尸山血海！",
  ["$m_heg__siling2"] = "我们的王权，就在这皑皑白骨上建成！",
  ["$m_heg__siling3"] = "天下已然如此，再乱一点又如何？",
  ["$m_heg__siling4"] = "西凉铁骑之下，尽是哀嚎！",
}

local H = require "packages.hegemony.util"

siling:addEffect("active", {
  anim_type = "offensive",
  prompt = "#m_heg__siling",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(siling.name, Player.HistoryPhase) == 0 and
      Fk:currentRoom():getBanner(siling.name)
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and
      H.compareKingdomWith(player, to_select) and
      to_select.deputyGeneral ~= "blank_shibing" and to_select.deputyGeneral ~= "blank_nvshibing"
  end,
  on_use = function(self, room, effect)
    local target = effect.tos[1]
    local skill = room:tableRandomPick(room:getBanner(siling.name))
    if room:askToUseActiveSkill(target, {
      skill_name = skill,
      prompt = "#m_heg__siling-invoke:::"..skill,
    }) then
      if not target.dead then
        H.removeGeneral(target, true)
      end
    end
  end,
})

siling:addEffect("targetmod", {
  residue_func = function (self, player, skill, scope, card, to)
    if player:hasSkill(siling.name) and card and card.trueName == "slash" and
      scope == Player.HistoryPhase then
      local n = 0
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        if p.general == "blank_shibing" or p.general == "blank_nvshibing" or
          p.deputyGeneral == "blank_shibing" or p.deputyGeneral == "blank_nvshibing" then
          n = n + 1
        end
      end
      return n
    end
  end,
})

siling:addAcquireEffect(function (self, player, is_start, src)
  local room = player.room
  if not room:getBanner(siling.name) then
    local skills = {}
    for g, _ in pairs(Fk.generals) do
      if Fk:canUseGeneral(g) then
        for _, s in ipairs(Fk.generals[g]:getSkillNameList()) do
          if Fk.skills[s]:hasTag(Skill.Limited) and Fk.skills[s]:isInstanceOf(ActiveSkill) then
            table.insertIfNeed(skills, s)
          end
        end
      end
    end
    if #skills > 0 then
      room:setBanner(siling.name, skills)
    end
  end
end)

return siling
