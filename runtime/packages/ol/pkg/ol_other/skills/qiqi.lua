local qiqi = fk.CreateSkill{
  name = "qiqi",
}

Fk:loadTranslationTable{
  ["qiqi"] = "期期",
  [":qiqi"] = "每轮限一次，当你使用牌指定目标时，若牌名字数不小于你的体力值，你可以摸两张牌，令此牌额外结算一次并进行判定，"..
  "若为<font color='red'>♥</font>，你减1点体力上限。",

  ["$qiqi1"] = "凤兮凤兮，故是一凤。",
  ["$qiqi2"] = "艾虽不善言辞，最信勤能补拙。",
}

qiqi:addEffect(fk.TargetSpecifying, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qiqi.name) and data.firstTarget and
      data.card:getNameLength(true) >= player.hp and
      player:usedSkillTimes(qiqi.name, Player.HistoryRound) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(2, qiqi.name)
    data.use.additionalEffect = (data.use.additionalEffect or 0) + 1
    if player.dead then return end
    local judge = {
      who = player,
      reason = qiqi.name,
      pattern = ".|.|^heart",
    }
    room:judge(judge)
    if judge.card and not judge:matchPattern() and not player.dead then
      room:changeMaxHp(player, -1)
    end
  end,
})

return qiqi
