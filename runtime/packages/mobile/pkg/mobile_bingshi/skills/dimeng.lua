
local dimeng = fk.CreateSkill{
  name = "m_shi__dimeng",
}

Fk:loadTranslationTable {
  ["m_shi__dimeng"] = "缔盟",
  [":m_shi__dimeng"] = "出牌阶段限一次，你可以令两名手牌数之差不大于3的角色交换手牌，然后你选择一项：" ..
  "1.弃置X张牌（不足则全弃）；2.交换后手牌数较少的角色摸X张牌（X为你已损失体力值）。",

  ["#m_shi__dimeng"] = "缔盟：令两名手牌数之差不大于%arg的角色交换手牌",
  ["m_shi__dimeng_discard"] = "弃置%arg张牌（不足全弃）",
  ["m_shi__dimeng_draw"] = "%dest摸%arg张牌",

  ["$m_shi__dimeng1"] = "两家联盟若成，则无虑强曹之患。",
  ["$m_shi__dimeng2"] = "今为将军陈以时势，望明缔盟之重也。",
}

dimeng:addEffect("active", {
  anim_type = "control",
  prompt = function (self, player, selected_cards, selected_targets)
    return "#m_shi__dimeng:::"..player:getLostHp()
  end,
  card_num = 0,
  target_num = 2,
  can_use = function(self, player)
    return player:usedSkillTimes(dimeng.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected == 0 then
      return true
    elseif #selected == 1 then
      local x1 = to_select:getHandcardNum()
      local x2 = selected[1]:getHandcardNum()
      return (x1 > 0 or x2 > 0) and math.abs(x1 - x2) <= 3
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target1 = effect.tos[1]
    local target2 = effect.tos[2]
    room:swapAllCards(player, { target1, target2 }, dimeng.name)
    local n = player:getLostHp()
    if not (player:isAlive() and player:isWounded()) then
      return
    end
    local choices = { "m_shi__dimeng_discard:::" .. n }
    local to = target1
    if target1:getHandcardNum() > target2:getHandcardNum() then
      to = target2
    elseif target1:getHandcardNum() == target2:getHandcardNum() then
      to = nil
    end
    if to and to:isAlive() then
      table.insert(choices, "m_shi__dimeng_draw::" .. to.id .. ":" .. n)
    end

    local choice = room:askToChoice(
      player,
      {
        choices = choices,
        skill_name = dimeng.name,
      }
    )
    if choice:startsWith("m_shi__dimeng_discard") then
      room:askToDiscard(
        player,
        {
          min_num = n,
          max_num = n,
          include_equip = true,
          skill_name = dimeng.name,
          cancelable = false,
        }
      )
    elseif to and to:isAlive() then
      to:drawCards(n, dimeng.name)
    end
  end,
})

return dimeng
