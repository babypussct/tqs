local qingtan = fk.CreateSkill {
  name = "os__qingtan",
}

Fk:loadTranslationTable{
  ["os__qingtan"] = "清谈",
  [":os__qingtan"] = "出牌阶段限两次，你可以令所有角色同时选择一张手牌并展示。你可以获得其中一种颜色的牌，然后展示此颜色牌的角色"..
  "各摸一张牌。弃置其余的牌。",

  ["#os__qingtan"] = "清谈：所有角色展示一张手牌，你获得其中一种颜色的牌，弃置其余牌",
  ["#os__qingtan-get"] = "清谈：选择获得其中一种颜色的牌",

  ["$os__qingtan1"] = "鸿鹄比翼游，群飞戏太清。",
  ["$os__qingtan2"] = "有之为有，恃无以生。",
}

qingtan:addEffect("active", {
  anim_type = "control",
  prompt = "#os__qingtan",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(qingtan.name, Player.HistoryPhase) < 2
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local targets = table.filter(room:getAlivePlayers(), function(p)
      return not p:isKongcheng()
    end)
    if #targets == 0 then return end
    room:doIndicate(player, targets)
    local result = room:askToJointCards(player, {
      players = targets,
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = qingtan.name,
      prompt = "#qingtan-card",
      cancelable = false,
    })
    local cards = {}
    for p, ids in pairs(result) do
      if table.contains(p:getCardIds("h"), ids[1]) then
        p:showCards(ids)
        table.insert(cards, ids[1])
      end
    end
    if player.dead or #cards == 0 then return end
    local suits = {}
    for _, id in ipairs(cards) do
      table.insertIfNeed(suits, Fk:getCardById(id):getColorString())
    end
    table.insert(suits, "Cancel")
    local choice = room:askToViewCardsAndChoice(player, {
      cards = cards,
      choices = suits,
      skill_name = qingtan.name,
      prompt = "#os__qingtan-get"
    })
    if choice ~= "Cancel" then
      for _, p in ipairs(targets) do
        if not player.dead and not p.dead then
          local id = result[p][1]
          if Fk:getCardById(id):getColorString() == choice and table.contains(p:getCardIds("h"), id) then
            table.removeOne(cards, id)
            if p ~= player then
              room:obtainCard(player, id, true, fk.ReasonPrey)
            end
            if not p.dead then
              p:drawCards(1, qingtan.name)
            end
          end
        end
      end
    end
    for _, p in ipairs(targets) do
      if not p.dead then
        local id = result[p][1]
        if table.contains(p:getCardIds("h"), id) and table.contains(cards, id) and not player:prohibitDiscard(id) then
          room:throwCard(id, qingtan.name, p, player)
        end
      end
    end
  end,
})

return qingtan
