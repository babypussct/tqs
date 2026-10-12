
local fengqil = fk.CreateSkill {
  name = "os__fengqil",
  tags = { Skill.Lord, Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["os__fengqil"] = "烽起",
  [":os__fengqil"] = "主公技，锁定技，群雄角色出牌阶段可因〖鬻爵〗交给你牌数量修改为4；" ..
  "武将牌上有主公技的角色成为〖革制〗目标时，其选项增加一项：获得其武将牌上的主公技。",
}

fengqil:addEffect("visibility", {})

return fengqil
