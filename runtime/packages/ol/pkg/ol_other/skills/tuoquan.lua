local tuoquan = fk.CreateSkill {
  name = "tuoquan",
  tags = { Skill.Compulsory },
  related_skills = { "dianzan" },
}

Fk:loadTranslationTable{
  ["tuoquan"] = "托权",
  [":tuoquan"] = "锁定技，游戏开始时，你令所有角色获得技能〖点赞〗；准备阶段，你沉迷享乐，失去因此获得的技能，" ..
  "请从相父为你准备的<a href='#tuoquan_fuchen'>“辅臣”</a>中选择两名上阵（获得选择武将的技能，觉醒技、限定技除外）。",

  ["#tuoquan_fuchen"] = "关羽、张飞、赵云、OL魏延、OL马谡、OL张翼、姜维、界黄忠，前八位均移除后出现OL蒋琬和OL费祎",
  ["@tuoquan_fuchen"] = "辅臣",

  ["$tuoquan1"] = "卿等既进尽忠言，自行斟酌损益便是。",
  ["$tuoquan2"] = "朕闻垂拱而治，诸卿自决便可。",
}

tuoquan:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(tuoquan.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      room:handleAddLoseSkills(p, "dianzan")
    end
  end,
})

tuoquan:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player.phase == Player.Start and
      player:hasSkill(tuoquan.name) and
      (#player:getTableMark("tuoquan_skills") > 0 or #player:getTableMark("tuoquan_removed") < 10)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tuoquanSkills = player:getTableMark("tuoquan_skills")
    room:setPlayerMark(player, "tuoquan_skills", 0)
    room:handleAddLoseSkills(player, "-" .. table.concat(tuoquanSkills, "|-"))
    room:setPlayerMark(player, "@tuoquan_fuchen", 0)
    room:handleAddLoseSkills(player, "xiangle", "anle")

    local fuchen = {
      "guanyu",
      "zhangfei",
      "zhaoyun",
      "m_ex__weiyan",
      "ol__masu",
      "ol__zhangyiy",
      "jiangwei",
      "ol_ex__huangzhong",
    }

    local fuchenRemoved = player:getTableMark("tuoquan_removed")
    if #fuchenRemoved > #fuchen then
      return false
    end

    fuchen = table.filter(fuchen, function(general) return not table.contains(fuchenRemoved, general) end)
    if #fuchen == 0 then
      fuchen = { "ol__jiangwan", "ol__feiyi" }
    end

    local generals = room:askToChooseGeneral(
      player,
      {
        generals = room:tableRandomPick(fuchen, 4),
        n = 2,
        no_convert = true,
      }
    )

    room:setPlayerMark(player, "@tuoquan_fuchen", generals)
    if player:hasSkill("xiangle", true, true) and table.contains(player.derivative_skills[Fk.skills["anle"]], Fk.skills["xiangle"]) then
      room:handleAddLoseSkills(player, "-xiangle", "anle")
    end
    for _, generalName in ipairs(generals) do
      for _, skillName in ipairs(Fk.generals[generalName]:getSkillNameList(true)) do
        local skill = Fk.skills[skillName]
        if not (skill:hasTag(Skill.Wake) or skill:hasTag(Skill.Limited) or player:hasSkill(skill)) then
          room:addTableMark(player, "tuoquan_skills", skillName)
          room:handleAddLoseSkills(player, skillName)
        end
      end
    end

    local xianglvCards = player:getPile("xianglv")
    if #xianglvCards > 0 and player:hasSkill("xianglv") then
      room:obtainCard(player, room:tableRandomPick(xianglvCards, #generals), true, fk.ReasonPrey, player, "xianglv")
    end
  end,
})

return tuoquan
