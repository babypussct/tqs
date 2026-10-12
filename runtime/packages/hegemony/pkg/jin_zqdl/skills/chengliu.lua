local chengliu = fk.CreateSkill {
  name = "heg__chengliu",
}

Fk:loadTranslationTable{
  ["heg__chengliu"] = "乘流",
  [":heg__chengliu"] = "出牌阶段限一次，你可以对一名装备区牌数小于你的角色造成1点伤害，然后你可以与其交换装备区的所有牌并重复此流程。",

  ["#heg__chengliu"] = "乘流：对一名装备数小于你的角色造成1点伤害，然后可以与其交换所有装备并重复此流程。",
  ["heg__chengliu_swap"] = "与%dest交换装备区的所有牌",

  ["$heg__chengliu1"] = "今威名已著，当直取敌都。",
  ["$heg__chengliu2"] = "顺流鼓棹，径造三山。",
}

chengliu:addEffect("active", {
  anim_type = "offensive",
  prompt = "#heg__chengliu",
  can_use = function (self, player)
    return player:usedSkillTimes(chengliu.name, Player.HistoryPhase) == 0 and
      table.find(Fk:currentRoom().alive_players, function(p)
        return #p:getCardIds("e") < #player:getCardIds("e")
      end)
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 1,
  target_filter = function (self, player, to_select, selected, selected_cards)
    return #to_select:getCardIds("e") < #player:getCardIds("e") and #selected == 0
  end,
  on_use = function (self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:damage{
      from = player,
      to = target,
      damage = 1,
      skillName = chengliu.name,
    }
    if player:isAlive() and target:isAlive() and
      room:askToChoice(player, {
        choices = { "heg__chengliu_swap::" .. target.id, "Cancel" },
        skill_name = chengliu.name,
      }) ~= "Cancel" then
        room:swapAllCards(player, {player, target}, chengliu.name, "e")
        if player:isAlive() and table.find(room.alive_players, function(p)
          return #p:getCardIds("e") < #player:getCardIds("e")
        end) then
          room:askToUseActiveSkill(player, {
            skill_name = chengliu.name,
            cancelable = true,
            prompt = "#heg__chengliu",
          })
        end
    end
  end
})

return chengliu
