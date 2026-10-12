local huandao = fk.CreateSkill {
  name = "huandao",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["huandao"] = "寰道",
  [":huandao"] = "限定技，出牌阶段，你可以选择一名其他角色，令其复原武将牌，然后其可随机获得一项同名武将的技能并选择失去一项其他技能。",

  ["#huandao"] = "寰道：令一名角色复原武将牌并获得同名武将技能",
  ["#huandao-choose"] = "寰道：你可以获得技能“%arg”，然后选择另一项技能失去",
  ["#huandao-lose"] = "寰道：请选择你要失去的技能",

  ["$huandao1"] = "一语一默，道尽医者慈悲。",
  ["$huandao2"] = "亦疾亦缓，抚平世间苦难。",
}

huandao:addEffect("active", {
  prompt = "#huandao",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(huandao.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local target = effect.tos[1]

    target:reset()
    if target.dead then return end
    local generals = Fk:getSameGenerals(target.general)
    local name = Fk.generals[target.general].trueName
    if name:startsWith("god") then
      table.insertTableIfNeed(generals, Fk:getSameGenerals(string.sub(name, 4)))
    else
      table.insertTableIfNeed(generals, Fk:getSameGenerals("god" .. name))
      local godGeneral = Fk.generals["god" .. name]
      if godGeneral and Fk:canUseGeneral(godGeneral.name) then
        table.insertIfNeed(generals, "god" .. name)
      end
    end

    if target.deputyGeneral and target.deputyGeneral ~= "" then
      table.insertTableIfNeed(generals, Fk:getSameGenerals(target.deputyGeneral))
      name = Fk.generals[target.deputyGeneral].trueName
      if name:startsWith("god") then
        table.insertTableIfNeed(generals, Fk:getSameGenerals(string.sub(name, 4)))
      else
        table.insertTableIfNeed(generals, Fk:getSameGenerals("god" .. name))
        local godGeneral = Fk.generals["god" .. name]
        if godGeneral and Fk:canUseGeneral(godGeneral.name) then
          table.insertIfNeed(generals, "god" .. name)
        end
      end
    end
    if #generals == 0 then return end

    local skill = room:tableRandomPick(Fk.generals[room:tableRandomPick(generals)]:getSkillNameList())
    local invoke = room:askToChoice(target, {
      choices = { skill, "Cancel" },
      skill_name = huandao.name,
      detailed = true,
      prompt = "#huandao-choose:::"..skill,
    })
    if invoke ~= "Cancel" then
      room:handleAddLoseSkills(target, skill)
      local choices = target:getSkillNameList()
      table.removeOne(choices, skill)
      if #choices > 0 then
        local choice = room:askToChoice(target, {
          choices = choices,
          skill_name = huandao.name,
          prompt = "#huandao-lose",
          detailed = true,
        })
        room:handleAddLoseSkills(target, "-"..choice)
      end
    end
  end,
})

return huandao
