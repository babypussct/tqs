
local shanxi = fk.CreateSkill{
  name = "m_shi__shanxi",
  max_branches_use_time = function(self, player)
    local ret = {}
    for _, to in ipairs(Fk:currentRoom().players) do
      ret[tostring(to.id)] = {
        [Player.HistoryPhase] = 1,
      }
    end
    return ret
  end,
}

Fk:loadTranslationTable{
  ["m_shi__shanxi"] = "闪袭",
  [":m_shi__shanxi"] = "出牌阶段每名角色限一次，你可以将一张应机牌当【决斗】对一名角色使用。",

  ["#m_shi__shanxi"] = "闪袭：将一张应机牌当【决斗】使用",

  ["$m_shi__shanxi1"] = "山越民丁散漫，遇我何以称军？",
  ["$m_shi__shanxi2"] = "山中风疾，我军兵厉，问尔何不归服？",
  ["$m_shi__shanxi3"] = "我军兵动如风，出之必伏山越！",
  ["$m_shi__shanxi4"] = "疾如雷霆之威，刃卷秋霜之寒！",
}

shanxi:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#m_shi__shanxi",
  handly_pile = true,
  card_filter = function (self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select, true):getMark("@@m_shi__qizhou") > 0
  end,
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".",
  },
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("duel")
    c.skillName = shanxi.name
    c:addSubcards(cards)
    return c
  end,
  before_use = function(self, player, use)
    player:addSkillBranchUseHistory(shanxi.name, tostring(use.tos[1].id), 1)
  end,
})

shanxi:addEffect("prohibit", {
  is_prohibited = function (self, from, to, card)
    return to and card and table.contains(card.skillNames, shanxi.name) and
      not shanxi:withinBranchTimesLimit(from, tostring(to.id), Player.HistoryPhase)
  end,
})

return shanxi
