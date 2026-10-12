local qianyao = fk.CreateSkill {
  name = "qianyao",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["qianyao"] = "潜曜",
  [":qianyao"] = "限定技，回合开始时，你可以摸X张牌，视为使用一张【杀】且依次执行等量项：1.此【杀】目标+1；2.此【杀】伤害+1；3.此【杀】不可响应"..
  "（X为当前轮数）。",

  ["#qianyao-slash"] = "潜曜：请视为使用一张带有%arg项效果的【杀】！",
  ["#qianyao-choose"] = "潜曜：你可以为此【杀】选择一个额外目标",
}

qianyao:addEffect(fk.TurnStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qianyao.name) and
      player:usedSkillTimes(qianyao.name, Player.HistoryGame) == 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local n = room:getBanner("RoundCount")
    player:drawCards(n, qianyao.name)
    if player.dead then return end
    n = math.min(n, 3)
    local use = room:askToUseVirtualCard(player, {
      name = "slash",
      skill_name = qianyao.name,
      prompt = "#qianyao-slash:::"..n,
      cancelable = false,
      extra_data = {
        bypass_times = true,
        extraUse = true,
      },
      skip = true,
    })
    if use == nil then return end
    local targets = UseCardData:new(use):getExtraTargets()
    if #targets > 0 then
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = qianyao.name,
        prompt = "#qianyao-choose",
        cancelable = true,
      })
      if #to > 0 then
        table.insert(use.tos, to[1])
        room:sortByAction(use.tos)
      end
    end
    if n > 1 then
      use.additionalDamage = 1
      if n > 2 then
        use.disresponsiveList = table.simpleClone(room.players)
      end
    end
    room:useCard(use)
  end,
})

return qianyao
