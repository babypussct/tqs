local zhuguo = fk.CreateSkill {
  name = "zhuguow",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["zhuguow"] = "蛀国",
  [":zhuguow"] = "锁定技，每回合限三次，牌堆牌数量增加后，你从牌堆底摸两张牌。",

  ["$zhuguow1"] = "让邺城燃烧！让奸贼陨落！",
  ["$zhuguow2"] = "一声魏王，没了五十万枯骨！",
}

zhuguo:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  times = function (self, player)
    return 3 - player:usedSkillTimes(zhuguo.name)
  end,
  can_trigger = function(self, event, target, player, data)
    --目前没有同时移除并加入牌堆牌的技能（一般过处理区），暂且偷懒
    --观星类技能可以发动、洗牌不能发动
    return player:hasSkill(zhuguo.name) and player:usedSkillTimes(zhuguo.name) < 3 and
      table.find(data, function(move)
        return move.toArea == Card.DrawPile and #move.moveInfo > 0
      end) ~= nil
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, zhuguo.name, "bottom")
  end,
})

return zhuguo
