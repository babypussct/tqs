local zhuanzhan = fk.CreateSkill {
  name = "heg__zhuanzhan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["heg__zhuanzhan"] = "转战",
  [":heg__zhuanzhan"] = "锁定技，若场上有未确定势力的角色，你使用【杀】无距离限制且不能指定已确定势力的角色为目标。",
}

zhuanzhan:addEffect("targetmod", {
  bypass_distances = function (self, player, skill, card, to)
    return player:hasSkill(zhuanzhan.name) and skill.trueName == "slash_skill" and
      table.find(Fk:currentRoom().alive_players, function (p)
        return p.kingdom ~= "unknown"
      end)
  end,
})

zhuanzhan:addEffect("prohibit", {
  is_prohibited = function (self, from, to, card)
    return from and from:hasSkill(zhuanzhan.name) and card and card.trueName == "slash" and to.kingdom ~= "unknown"
  end,
})

return zhuanzhan
