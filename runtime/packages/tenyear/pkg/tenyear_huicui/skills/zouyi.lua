local zouyi = fk.CreateSkill{
  name = "zouyi",
}

Fk:loadTranslationTable{
  ["zouyi"] = "诹议",
  [":zouyi"] = "出牌阶段限一次，你可以选择至多两项：1.摸两张牌，然后可以弃置一名其他角色一张牌；2.弃置一张牌，然后可以令一名其他角色摸两张牌。"..
  "结算后，〖掩袭〗使用次数增加手牌数与你相同的角色数并回复等量体力。",

  ["zouyi_draw"] = "摸两张牌，然后可以弃置一名其他角色一张牌",
  ["zouyi_discard"] = "弃一张牌，然后可以令一名其他角色摸两张牌",
  ["zouyi_beishui"] = "执行以上两项",
  ["#zouyi1-choose"] = "诹议：你可以弃置一名其他角色一张牌",
  ["#zouyi2-choose"] = "诹议：你可以令一名其他角色摸两张牌",

  ["$zouyi1"] = "今夜月黑风高，正乃除贼良时！",
  ["$zouyi2"] = "效日磾讨莽何罗，使汉祚不移！",
}

zouyi:addEffect("active", {
  anim_type = "drawcard",
  card_num = 0,
  target_num = 0,
  interaction = function (self, player)
    local choices = { "zouyi_draw", "zouyi_beishui" }
    if table.find(player:getCardIds("he"), function (id)
      return not player:prohibitDiscard(id)
    end) then
      table.insert(choices, 2, "zouyi_discard")
    end
    return UI.ComboBox { choices = choices , all_choices = { "zouyi_draw", "zouyi_discard", "zouyi_beishui" }}
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(zouyi.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local choice = self.interaction.data
    if choice ~= "zouyi_discard" then
      player:drawCards(2, zouyi.name)
      if player.dead then return end
      local targets = table.filter(room:getOtherPlayers(player, false), function (p)
        return not p:isNude()
      end)
      if #targets > 0 then
        local to = room:askToChoosePlayers(player, {
          min_num = 1,
          max_num = 1,
          targets = targets,
          skill_name = zouyi.name,
          prompt = "#zouyi1-choose",
          cancelable = true,
        })
        if #to > 0 then
          to = to[1]
          local card = room:askToChooseCard(player, {
            target = to,
            flag = "he",
            skill_name = zouyi.name,
          })
          room:throwCard(card, zouyi.name, to, player)
          if player.dead then return end
        end
      end
    end
    if choice ~= "zouyi_draw" then
      if #room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = zouyi.name,
        cancelable = false,
      }) > 0 then
        if player.dead then return end
        if #room:getOtherPlayers(player, false) > 0 then
          local to = room:askToChoosePlayers(player, {
            min_num = 1,
            max_num = 1,
            targets = room:getOtherPlayers(player, false),
            skill_name = zouyi.name,
            prompt = "#zouyi2-choose",
            cancelable = true,
          })
          if #to > 0 then
            to[1]:drawCards(2, zouyi.name)
            if player.dead then return end
          end
        end
      end
    end

    local n = #table.filter(room.alive_players, function (p)
      return p:getHandcardNum() == player:getHandcardNum()
    end)
    if player:hasSkill("yanxij", true) then
      room:addPlayerMark(player, "yanxij", n)
    end
    room:recover{
      who = player,
      num = n,
      skillName = zouyi.name,
      recoverBy = player,
    }
  end,
})

return zouyi
