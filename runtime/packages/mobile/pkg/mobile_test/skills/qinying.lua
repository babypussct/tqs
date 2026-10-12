local qinying = fk.CreateSkill {
  name = "qinying",
}

Fk:loadTranslationTable{
  ["qinying"] = "钦英",
  [":qinying"] = "出牌阶段限一次，你可以重铸任意张牌，视为使用一张【决斗】。若如此做，此【决斗】结算过程中限X次（X为你以此法重铸的牌数），"..
  "你或目标角色可以弃置区域中的一张牌，视为打出一张【杀】。",

  ["#qinying"] = "钦英：你可以重铸任意张牌，视为使用一张【决斗】，双方可以弃一张牌以视为打出【杀】",

  ["$qinying1"] = "虽穷不处亡国之势，虽贫不受污君之禄。",
  ["$qinying2"] = "太公七十而不自达，孙叔敖三去相而不自悔。",
  ["$qinying3"] = "知命者待时而举，岂曰时无英雄乎？",
  ["$qinying4"] = "但因明主未遇，故潜居抱道以待其时。",
}

qinying:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#qinying",
  filter_pattern = {
    min_num = 0,
    max_num = 0,
    pattern = "",
    subcards = {}
  },
  card_filter = Util.TrueFunc,
  view_as = function(self, player, cards)
    if #cards == 0 then return end
    local card = Fk:cloneCard("duel")
    card.skillName = qinying.name
    card:addFakeSubcards(cards)
    return card
  end,
  before_use = function (self, player, use)
    local room = player.room
    if #player:getTableMark(qinying.name) < 3 then
      room:setBanner(qinying.name, #use.card.fake_subcards)
      if #player:getTableMark(qinying.name) > 0 then
        room:setBanner("qinying_prohibit", player:getMark(qinying.name))
      end
      room:handleAddLoseSkills(player, "qinying&", nil, false, true)
      for _, p in ipairs(use.tos) do
        room:handleAddLoseSkills(p, "qinying&", nil, false, true)
      end
    end
    room:recastCard(use.card.fake_subcards, player, qinying.name)
  end,
  after_use = function (self, player, use)
    local room = player.room
    room:setBanner(qinying.name, nil)
    room:setBanner("qinying_prohibit", nil)
    for _, p in ipairs(room.players) do
      room:handleAddLoseSkills(p, "-qinying&", nil, false, true)
    end
  end,
  enabled_at_play = function (self, player)
    return player:usedSkillTimes(qinying.name, Player.HistoryPhase) == 0
  end,
})

return qinying
