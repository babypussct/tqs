local qimou = fk.CreateSkill{
  name = "m_ex__qimou",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable {
  ["m_ex__qimou"] = "奇谋",
  [":m_ex__qimou"] = "限定技，出牌阶段，你可以失去任意点体力，直到回合结束，你计算与其他角色的距离-X，且你可以多使用X张【杀】"..
  "（X为你以此法失去的体力）。",

  ["@m_ex__qimou-turn"] = "奇谋",
  ["#m_ex__qimou"] = "奇谋：失去任意点体力，本回合与其他角色减等量距离，可多出等量张杀",

  ["$m_ex__qimou1"] = "轻兵出子午，直取魏王都。",
  ["$m_ex__qimou2"] = "哼，丞相奇谋为短，吾以涉险为长！",
}

qimou:addEffect("active", {
  anim_type = "offensive",
  prompt = "#m_ex__qimou",
  card_num = 0,
  target_num = 0,
  interaction = function(self, player)
    return UI.Spin {
      from = 1,
      to = player.hp,
    }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(qimou.name, Player.HistoryGame) == 0 and player.hp > 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local tolose = self.interaction.data
    room:loseHp(player, tolose, qimou.name)
    if player.dead then return end
    room:addPlayerMark(player, "@m_ex__qimou-turn", tolose)
  end,
})

qimou:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return player:getMark("@m_ex__qimou-turn")
    end
  end,
})

qimou:addEffect("distance", {
  correct_func = function(self, from, to)
    return -from:getMark("@m_ex__qimou-turn")
  end,
})

return qimou