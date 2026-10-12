local zhongliu = fk.CreateSkill{
  name = "zhongliu",
  tags = { Skill.Family, Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["zhongliu"] = "中流",
  [":zhongliu"] = "宗族技，锁定技，当你使用牌时，若不为同族角色的手牌，你视为未发动此武将牌上的技能。",
}

local U = require "packages.utility.utility"

zhongliu:addEffect(fk.CardUsing, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhongliu.name) and player == target then
      if data.subcardsFromInfo == nil or #data.subcardsFromInfo == 0 then return true end
      for _, info in ipairs(data.subcardsFromInfo) do
        if info.fromArea == Card.PlayerHand and info.from and U.FamilyMember(player, info.from) then
          return false
        end
      end
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local all_skills = Fk.generals[player.general]:getSkillNameList()
    if table.contains(all_skills, zhongliu.name) then
      for _, skill_name in ipairs(all_skills) do
        player:clearSkillHistory(skill_name)
      end
    end
    if player.deputyGeneral and player.deputyGeneral ~= "" then
      all_skills = Fk.generals[player.deputyGeneral]:getSkillNameList()
      if table.contains(all_skills, zhongliu.name) then
        for _, skill_name in ipairs(all_skills) do
          player:clearSkillHistory(skill_name)
        end
      end
    end
  end,
})

return zhongliu
