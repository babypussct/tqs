local hanzhan = fk.CreateSkill{
  name = "mobile__hanzhan",
}

Fk:loadTranslationTable{
  ["mobile__hanzhan"] = "酣战",
  [":mobile__hanzhan"] = "出牌阶段限一次，你可以选择一名其他角色，你与其分别将手牌摸至X张（X为各自体力上限，且每名角色至多摸三张），" ..
  "然后视为你对其使用一张【决斗】。",

  ["#mobile__hanzhan"] = "酣战：你可以与一名其他角色摸牌，然后视为你对其使用【决斗】",

  ["$mobile__hanzhan1"] = "君壮情烈胆，某必当奉陪！",
  ["$mobile__hanzhan2"] = "哼！你我再斗一番，方知孰为霸王！",
}

hanzhan:addEffect("active", {
  anim_type = "offensive",
  prompt = "#mobile__hanzhan",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(hanzhan.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]

    for _, p in ipairs({ player, target }) do
      if not p.dead then
        local n = p.maxHp
        local change = player:getMark("@mobile__zhenfeng_"..hanzhan.name)
        if change ~= 0 then
          if change == "mobile__zhenfeng_hp" then
            n = p.hp
          elseif change == "mobile__zhenfeng_lostHp" then
            n = p:getLostHp()
          elseif change == "mobile__zhenfeng_alives" then
            n = #room.alive_players
          end
        end
        n = n - p:getHandcardNum()
        if n > 0 then
          p:drawCards(math.min(3, n), hanzhan.name)
        end
      end
    end

    if not player.dead and not target.dead then
      room:useVirtualCard("duel", nil, player, target, hanzhan.name)
    end
  end,
})

return hanzhan
