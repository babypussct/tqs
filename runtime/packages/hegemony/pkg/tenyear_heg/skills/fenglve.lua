
local fenglve = fk.CreateSkill{
  name = "ty_heg__fenglve",
}
fenglve:addEffect("active", {
  anim_type = "control",
  prompt = "#ty_heg__fenglve-active",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(fenglve.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and not to_select:isKongcheng()
  end,
  on_use = function (self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local pindian = player:pindian({target}, fenglve.name)
    if pindian.results[target].winner == player then
      if not (player.dead or target.dead or target:isNude()) then
        local cards = target:getCardIds("hej")
        if #cards > 2 then
          cards = room:askToChooseCards(target, {
            target = target,
            min = 2,
            max = 2,
            flag = "hej",
            skill_name = fenglve.name,
          })
        end
        room:moveCardTo(cards, Player.Hand, player, fk.ReasonGive, fenglve.name, nil, false, player)
      end
    elseif pindian.results[target].winner == target then
      if not (player.dead or target.dead or player:isNude()) then
        local cards2 = room:askToCards(player, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = fenglve.name,
          prompt = "#ty_heg__fenglve-give::" .. target.id,
          cancelable = false,
        })
        room:obtainCard(target, cards2, false, fk.ReasonGive)
      end
    end
    if player.dead or target.dead then return false end
    if room:askToChoice(player, {
      choices = {
        "ty_heg__fenglve_mn_ask::" .. target.id,
        "Cancel",
      },
      skill_name = fenglve.name,
    }) ~= "Cancel" then
      room:setPlayerMark(target, "@@ty_heg__fenglve_manoeuvre", 1)
      room:handleAddLoseSkills(target, "ty_heg__fenglve_manoeuvre", nil)
    end
  end,
})

Fk:loadTranslationTable{
  ["ty_heg__fenglve"] = "锋略",
  [":ty_heg__fenglve"] = "出牌阶段限一次，你可和一名其他角色拼点，若你赢，该角色交给你其区域内的两张牌；若其赢，你交给其一张牌。<br>"..
  "<a href='ty_heg_zongheng'>纵横</a>：交换〖锋略〗描述中的“一张牌”和“两张牌”。",

  ["#ty_heg__fenglve-active"] = "发动“锋略”，与一名角色拼点",
  ["#ty_heg__fenglve-give"] = "锋略：选择 %arg 张牌交给 %dest",
  ["ty_heg__fenglve_mn_ask"] = "令%dest获得〖锋略（纵横）〗直到其下回合结束",
  ["@@ty_heg__fenglve_manoeuvre"] = "锋略 纵横",

  ["$ty_heg__fenglve1"] = "冀州宝地，本当贤者居之。",
  ["$ty_heg__fenglve2"] = "当今敢称贤者，唯袁氏本初一人。",
}

return fenglve
