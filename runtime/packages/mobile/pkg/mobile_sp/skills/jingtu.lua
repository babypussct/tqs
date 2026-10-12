local jingtu = fk.CreateSkill {
  name = "jingtu",
  tags = { Skill.Limited },
  related_skills = { "mobile__fozong" },
}

Fk:loadTranslationTable{
  ["jingtu"] = "净土",
  [":jingtu"] = "限定技，出牌阶段，你可以选择一项：1.获得你的所有黑色“业”并对一名角色造成等量伤害；2.获得你的所有红色“业”，" ..
  "令一名角色加等量体力上限并回复等量体力。若你两种颜色的“业”数量相等且均大于1，你可背水。最后你失去技能〖浮图〗并获得技能〖佛宗〗。",

  ["#jingtu"] = "净土：你可获得“业”并执行对应效果",
  ["jingtu_black"] = "获得黑色“业”",
  ["jingtu_red"] = "获得红色“业”",
  ["@jingtu-color"] = "净土",
  ["#jingtu-damage"] = "净土：请对一名角色造成%arg点伤害",
  ["#jingtu-heal"] = "净土：请令一名角色加%arg点体力上限并回复%arg点体力",

  ["$jingtu1"] = "拔诸勤苦生死根本，速成无上正等正觉。",
  ["$jingtu2"] = "当信佛经语深，当信积善得福。",
  ["$jingtu3"] = "钵器自然在前，饮食自然盈满。",
  ["$jingtu4"] = "思衣得衣，思食得食，一切唯心造。",
  ["$jingtu5"] = "杀生为度生，行恶即抑恶。",
  ["$jingtu6"] = "以己为灯，勤修自证。",
}

jingtu:addEffect("active", {
  prompt = "#jingtu",
  can_use = function(self, player)
    return player:usedSkillTimes(jingtu.name, Player.HistoryGame) == 0 and #player:getPile("futu_ye") > 0
  end,
  interaction = function(self, player)
    local choices = {}
    local blackCards = table.filter(player:getPile("futu_ye"), function(id) return Fk:getCardById(id).color == Card.Black end)
    local redCards = table.filter(player:getPile("futu_ye"), function(id) return Fk:getCardById(id).color == Card.Red end)
    if #blackCards > 0 then
      table.insert(choices, "jingtu_black")
    end
    if #redCards > 0 then
      table.insert(choices, "jingtu_red")
    end
    if #blackCards > 1 and #redCards > 1 and #blackCards == #redCards then
      table.insert(choices, "beishui")
    end
    if #choices == 0 then
      return
    end

    return UI.ComboBox { choices = choices, all_choices = { "jingtu_black", "jingtu_red", "beishui" } }
  end,
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = jingtu.name
    local player = effect.from
    if self.interaction.data ~= "jingtu_red" then
      local blackCards = table.filter(player:getPile("futu_ye"), function(id) return Fk:getCardById(id).color == Card.Black end)
      local blackNum = #blackCards
      room:obtainCard(player, blackCards, true, fk.ReasonJustMove, player, skillName)
      room:addTableMark(player, "@jingtu-color", "black")
      local tos = room:askToChoosePlayers(
        player,
        {
          min_num = 1,
          max_num = 1,
          targets = room:getAlivePlayers(false),
          skill_name = skillName,
          prompt = "#jingtu-damage:::" .. blackNum,
          cancelable = false,
        }
      )

      room:damage{
        from = player,
        to = tos[1],
        damage = blackNum,
        skillName = skillName,
      }
    end

    if self.interaction.data ~= "jingtu_black" then
      local redCards = table.filter(player:getPile("futu_ye"), function(id) return Fk:getCardById(id).color == Card.Red end)
      local redNum = #redCards
      room:obtainCard(player, redCards, true, fk.ReasonJustMove, player, skillName)
      room:addTableMark(player, "@jingtu-color", "red")

      local tos = room:askToChoosePlayers(
        player,
        {
          min_num = 1,
          max_num = 1,
          targets = room:getAlivePlayers(false),
          skill_name = skillName,
          prompt = "#jingtu-heal:::" .. redNum,
          cancelable = false,
        }
      )

      room:changeMaxHp(tos[1], redNum)
      room:recover{
        who = tos[1],
        num = redNum,
        recoverBy = player,
        skillName = skillName,
      }
    end

    room:handleAddLoseSkills(player, "-futu|mobile__fozong")
  end,
})

return jingtu
