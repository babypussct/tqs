local jiaheOther = fk.CreateSkill{
  name = "ld__jiahe_other&",
  related_skills = { "ld__lordsunquan_yingzi", "ld__lordsunquan_haoshi", "ld__lordsunquan_shelie", "ld__lordsunquan_duoshi" }
}

Fk:loadTranslationTable{
  ["ld__jiahe_other&"] = "烽火图",
  [":ld__jiahe_other&"] = "①出牌阶段限一次，你可以将一张装备牌置于“缘江烽火图”上，称为“烽火”。<br>" ..
  "②准备阶段，你可以根据“烽火”数量选择获得对应的技能直至其回合结束：<br>"..
  "不小于一，〖英姿〗；不小于二，〖好施〗；不小于三，〖涉猎〗；不小于四，〖度势〗；不小于五，可额外选择一项。",
  ["#fenghuotu"] = "缘江烽火图",
  ["#ld__jiahe_other"] = "缘江烽火图：将一张装备牌置于%src的“缘江烽火图”上，称为“烽火”",
  ["lord_fenghuo"] = "烽火",
}

local H = require "packages.hegemony.util"
jiaheOther:addEffect("active", {
  prompt = function(self, player)
    local to = H.getHegLord(Fk:currentRoom(), player)
    return "#ld__jiahe_other:" .. to.id
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(jiaheOther.name, Player.HistoryPhase) == 0 and
      H.hasHegLordSkill(Fk:currentRoom(), player, "jiahe")
  end,
  card_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected < 1 and Fk:getCardById(to_select).type == Card.TypeEquip
  end,
  target_num = 0,
  on_use = function(self, room, effect)
    local player = effect.from
    local to = H.getHegLord(room, player) --[[@as ServerPlayer]]
    if to and to:hasSkill("jiahe") then
      to:addToPile("lord_fenghuo", effect.cards, true, jiaheOther.name)
    end
  end,
})

return jiaheOther
