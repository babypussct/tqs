local weimeng = fk.CreateSkill{
  name = "ty_heg__weimeng",
}
weimeng:addEffect("active", {
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = function (self, player, selected, selected_cards)
    return "#ty_heg__weimeng:::"..player.hp
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(weimeng.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and not to_select:isKongcheng()
  end,
  on_use = function (self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local cards = room:askToChooseCards(player, {
      target = target,
      min = 1,
      max = player.hp,
      flag = "h",
      skill_name = weimeng.name,
    })
    room:obtainCard(player, cards, false, fk.ReasonPrey)
    if player.dead or player:isNude() or target.dead then return end
    local cards2 = player:getCardIds("he")
    if #cards2 > #cards then
      cards2 = room:askToCards(player, {
        min_num = #cards,
        max_num = #cards,
        include_equip = true,
        skill_name = weimeng.name,
        prompt = "#ty_heg__weimeng-give::"..target.id..":"..#cards,
        cancelable = false,
      })
    end
    room:obtainCard(target, cards2, false, fk.ReasonGive)
    if room:askToChoice(player, {
      choices = {
        "ty_heg__weimeng_mn_ask::" .. target.id,
        "Cancel",
      },
      skill_name = weimeng.name
    }) ~= "Cancel" then
      room:setPlayerMark(target, "@@ty_heg__weimeng_manoeuvre", 1)
      room:handleAddLoseSkills(target, "ty_heg__weimeng_manoeuvre", nil)
    end
  end,
})

Fk:loadTranslationTable{
  ["ty_heg__weimeng"] = "危盟",
  [":ty_heg__weimeng"] = "出牌阶段限一次，你可选择一名其他角色，获得其至多X张手牌，然后交给其等量的牌（X为你的体力值）。<br>"..
  "<a href='ty_heg_zongheng'>纵横</a>：〖危盟〗描述中的X改为1。",

  ["#ty_heg__weimeng-give"] = "危盟：交还 %dest %arg 张牌。",
  ["ty_heg__weimeng_mn_ask"] = "令%dest获得〖危盟（纵横）〗直到其下回合结束。",
  ["@@ty_heg__weimeng_manoeuvre"] = "危盟 纵横",
  ["#ty_heg__weimeng"] = "危盟：获得一名其他角色至多%arg张牌，交还等量牌。",

  ["$ty_heg__weimeng1"] = "此礼献于友邦，共赴兴汉大业！",
  ["$ty_heg__weimeng2"] = "吴有三江之守，何故委身侍魏？",
}

return weimeng
