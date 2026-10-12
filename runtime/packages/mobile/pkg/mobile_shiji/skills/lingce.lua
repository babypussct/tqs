local lingce = fk.CreateSkill {
  name = "lingce",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["lingce"] = "灵策",
  [":lingce"] = "锁定技，当非虚拟且非转化的锦囊牌被使用时，若此牌的牌名属于<a href='bag_of_tricks'>智囊</a>牌名、〖定汉〗已记录的牌名或"..
  "【奇正相生】，你摸一张牌。",

  ["bag_of_tricks"] = "#\"<b>智囊</b>\" ：即【过河拆桥】【无懈可击】【无中生有】",

  ["$lingce1"] = "绍士卒虽众，其实难用，必无为也。",
  ["$lingce2"] = "袁军不过一盘砂砾，主公用奇则散。",
}

lingce:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(lingce.name) and not data.card:isVirtual() and
      (
        table.contains({"dismantlement", "nullification", "ex_nihilo"}, data.card.trueName) or
        table.contains(player:getTableMark("@$dinghan"), data.card.trueName) or
        data.card.trueName == "raid_and_frontal_attack"
      )
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, lingce.name)
  end,
})

return lingce
