local ganglie = fk.CreateSkill{
  name = "hs__ganglie",
}

Fk:loadTranslationTable{
  ["hs__ganglie"] = "刚烈",
  [":hs__ganglie"] = "当你受到伤害后，你可判定，若结果为：红色，你对来源造成1点伤害；黑色，你弃置来源的一张牌。",

  ["$hs__ganglie1"] = "鼠辈，竟敢伤我！",
  ["$hs__ganglie2"] = "以彼之道，还施彼身！",
}

ganglie:addEffect(fk.Damaged, {
  anim_type = "masochism",
  on_trigger = function(self, event, target, player, data)
    self:doCost(event, target, player, data)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = data.from
    if from and not from.dead then room:doIndicate(player, {from}) end
    local judge = {
      who = player,
      reason = ganglie.name,
      pattern = ".",
    }
    room:judge(judge)
    if judge.card.color == Card.Red and from and not from.dead then
      room:damage{
        from = player,
        to = from,
        damage = 1,
        skillName = ganglie.name,
      }
    elseif judge.card.color == Card.Black and from and not from:isNude() and not from.dead then
      local cid = room:askToChooseCard(player, {target = from, flag = "he", skill_name = ganglie.name})
      room:throwCard({cid}, ganglie.name, from, player)
    end
  end
})

return ganglie
