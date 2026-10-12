
local fenglve_mn = fk.CreateSkill{
  name = "ty_heg__fenglve_manoeuvre",
}
fenglve_mn:addEffect("active", {
  anim_type = "control",
  prompt = "#ty_heg__fenglve-active",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(fenglve_mn.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and not to_select:isKongcheng()
  end,
  on_use = function (self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local pindian = player:pindian({target}, fenglve_mn.name)
    if pindian.results[target].winner == player then
      if not (player.dead or target.dead or target:isNude()) then
        local cards1 = room:askToChooseCard(target, {
          target = target,
          flag = "hej",
          skill_name = fenglve_mn.name,
        })
        room:obtainCard(player, cards1, false, fk.ReasonGive)
      end
    elseif pindian.results[target].winner == target then
      if not (player.dead or target.dead or player:isNude()) then
        local cards = player:getCardIds("he")
        if #cards > 2 then
          cards = room:askToCards(player, {
            min_num = 2,
            max_num = 2,
            include_equip = true,
            skill_name = fenglve_mn.name,
            prompt = "#ty_heg__fenglve-give::" .. target.id .. ":2",
            cancelable = false,
          })
        end
        room:moveCardTo(cards, Player.Hand, target, fk.ReasonGive, fenglve_mn.name, nil, false, player.id)
      end
    end
  end,
})

fenglve_mn:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill("ty_heg__fenglve_manoeuvre", true, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:handleAddLoseSkills(player, "-ty_heg__fenglve_manoeuvre", nil)
    room:setPlayerMark(player, "@@ty_heg__fenglve_manoeuvre", 0)
  end,
})

Fk:loadTranslationTable{
  ["ty_heg__fenglve_manoeuvre"] = "锋略⇋",
  [":ty_heg__fenglve_manoeuvre"] = "出牌阶段限一次，你可以和一名其他角色拼点，若你赢，该角色交给你其区域内的一张牌；若其赢，你交给其两张牌。",

}

return fenglve_mn
