local chushan = fk.CreateSkill {
  name = "chushan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["chushan"] = "出山",
  [":chushan"] = "锁定技，游戏开始时，你从随机六项技能中选择两项技能获得。",

  ["#chushan-choose"] = "出山：请选择两个技能出战（右键或长按可查看技能描述）",
  ["@chushan_skills"] = "",
}

local U = require "packages.utility.utility"

chushan:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(chushan.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local generals = Fk:getGeneralsRandomly(6, nil, { "wuming" })
    local skills = {}
    for _, general in ipairs(generals) do
      table.insertIfNeed(skills, room:tableRandomPick(general:getSkillNameList()))
    end

    skills = U.askToChooseSkills(player, {
      skill_name = chushan.name, prompt = "#chushan-choose",
      min_num = 2, max_num = 2,
      skills = skills,
      generals = table.map(generals, Util.NameMapper),
    })

    if #skills > 0 then
      local realNames = table.map(skills, Util.TranslateMapper)
      room:setPlayerMark(player, "@chushan_skills", "<font color='burlywood'>" .. table.concat(realNames, " ") .. "</font>")
      room:handleAddLoseSkills(player, table.concat(skills, "|"))
    end
  end,
})

return chushan
