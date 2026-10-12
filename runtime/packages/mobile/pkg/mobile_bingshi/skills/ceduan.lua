local ceduan = fk.CreateSkill{
  name = "m_shi__ceduan",
}

Fk:loadTranslationTable{
  ["m_shi__ceduan"] = "策断",
  [":m_shi__ceduan"] = "出牌阶段限一次，你可以选择一名攻击范围内包含你的角色，其攻击范围内的所有角色同时展示一张手牌，"..
  "然后你将手牌中展示牌最多颜色的所有牌当一张不计入次数限制的任意一种【杀】对其使用。若造成伤害，你摸一张牌。",

  ["#m_shi__ceduan"] = "策断：选择一名角色，将手牌中一种颜色的牌当一种【杀】对其使用",
  ["#m_shi__ceduan-show"] = "策断：展示一张手牌，根据颜色 %src 将对 %dest 使用【杀】",
  ["#m_shi__ceduan-slash"] = "策断：选择一种【杀】对 %dest 使用",

  ["$m_shi__ceduan1"] = "若蒙救援，使为外藩，则吴人可挫也。",
  ["$m_shi__ceduan2"] = "鄙郡虽小，形便之国也。",
  ["$m_shi__ceduan3"] = "江东虎狼，非王师不能制之。",
}

ceduan:addEffect("active", {
  anim_type = "offensive",
  max_phase_use_time = 1,
  prompt = "#m_shi__ceduan",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(ceduan.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select:inMyAttackRange(player)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local targets = table.filter(room.alive_players, function (p)
      return not p:isKongcheng() and target:inMyAttackRange(p)
    end)
    if #targets == 0 then return end
    local result = room:askToJointCards(player, {
      players = targets,
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = ceduan.name,
      cancelable = false,
      prompt = "#m_shi__ceduan-show:"..player.id..":"..target.id,
    })
    local red, black = 0, 0
    for p, c in pairs(result) do
      if table.contains(p:getCardIds("h"), c[1]) then
        p:showCards(c)
      end
      local color = Fk:getCardById(c[1]).color
      if color == Card.Red then
        red = red + 1
      elseif color == Card.Black then
        black = black + 1
      end
    end
    if red == black or (red == 0 and black == 0) then return end
    local cards = {}
    if red > black then
      cards = table.filter(player:getCardIds("h"), function (id)
        return Fk:getCardById(id).color == Card.Red
      end)
    else
      cards = table.filter(player:getCardIds("h"), function (id)
        return Fk:getCardById(id).color == Card.Black
      end)
    end
    if #cards == 0 then return end
    local names, all_names = {}, {}
    for _, name in ipairs(Fk:getAllCardNames("b", false)) do
      if not not string.find(name, "slash") then
        table.insertIfNeed(all_names, name)
      end
    end
    if #all_names == 0 then return end
    for _, name in ipairs(all_names) do
      local card = Fk:cloneCard(name)
      card:addFakeSubcards(cards)
      if player:canUseTo(card, target, { bypass_distances = true, bypass_times = true }) then
        table.insertIfNeed(names, name)
      end
    end
    local choice = room:askToChoice(player, {
      choices = names,
      skill_name = ceduan.name,
      all_choices = all_names,
      prompt = "#m_shi__ceduan-slash::"..target.id,
    })
    local use = room:useVirtualCard(choice, cards, player, target, ceduan.name, true)
    if use and use.damageDealt and not player.dead then
      player:drawCards(1, ceduan.name)
    end
  end,
})

return ceduan
