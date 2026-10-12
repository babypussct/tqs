local quxi = fk.CreateSkill{
  name = "quxig",
  max_branches_use_time = {
    ["jink"] = {
      [Player.HistoryPhase] = 1
    },
    ["peach"] = {
      [Player.HistoryPhase] = 1
    },
  }
}

Fk:loadTranslationTable{
  ["quxig"] = "趋袭",
  [":quxig"] = "出牌阶段各限一次，你的【闪】/【桃】可以当做【过河拆桥】/【顺手牵羊】使用。",

  ["#quxig"] = "趋袭：将【闪】/【桃】当做【过河拆桥】/【顺手牵羊】使用",

  ["$quxig1"] = "",
  ["$quxig2"] = "",
}

quxi:addEffect("viewas", {
  pattern = "snatch,dismantlement",
  prompt = "#quxig",
  anim_type = "control",
  handly_pile = true,
  filter_pattern = function(self, player, card_name)
    local vs_pattern = {
      max_num = 1,
      min_num = 1,
      pattern = "jink,peach",
    }
    if card_name == "dismantlement" then
      vs_pattern.pattern = "jink"
    elseif card_name == "snatch" then
      vs_pattern.pattern = "peach"
    end
    return vs_pattern
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local name = Fk:getCardById(cards[1]).trueName
    if not quxi:withinBranchTimesLimit(player, name, Player.HistoryPhase) then return end
    local c
    if name == "jink" then
      c = Fk:cloneCard("dismantlement")
    elseif name == "peach" then
      c = Fk:cloneCard("snatch")
    else
      return nil
    end
    c.skillName = quxi.name
    c:addSubcard(cards[1])
    return c
  end,
  history_branch = function(self, player, data)
    return Fk:getCardById(data.cards[1]).trueName
  end,
  enabled_at_response = Util.FalseFunc,
}, { check_skill_limit = true })

return quxi
