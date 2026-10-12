local zezhu = fk.CreateSkill {
  name = "ol_heg__zezhu",
}

Fk:loadTranslationTable {
  ["ol_heg__zezhu"] = "择主",
  [":ol_heg__zezhu"] = "出牌阶段限一次，你可以获得相邻角色各一张牌，然后交给其各一张牌。",

  ["#ol_heg__zezhu"] = "择主：获得相邻角色各一张牌，然后交给其各一张牌",
  ["#ol_heg__zezhu-prey"] = "择主：获得 %dest 区域内一张牌",
  ["#ol_heg__zezhu-give"] = "择主：交给 %dest 一张牌",
}

zezhu:addEffect("active", {
  anim_type = "control",
  prompt = "#ol_heg__zezhu",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(zezhu.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local prev = player:getLastAlive()
    local next = player:getNextAlive()
    local targets = { prev, next }
    room:doIndicate(player, targets)
    for _, p in ipairs(targets) do
      if player.dead then return end
      if not p.dead and not p:isNude() then
        local card = room:askToChooseCard(player,{
          target = p,
          flag = "he",
          skill_name = zezhu.name,
          prompt = "#ol_heg__zezhu-prey::"..p.id,
        })
        room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, zezhu.name, nil, false, player)
      end
    end
    for _, p in ipairs(targets) do
      if player.dead or player:isNude() then return end
      local card = room:askToCards(player,{
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = zezhu.name,
        prompt = "#ol_heg__zezhu-give::"..p.id,
        cancelable = false,
      })
      room:moveCardTo(card, Card.PlayerHand, p, fk.ReasonGive, zezhu.name, nil, false, player)
    end
  end,
})

return zezhu
