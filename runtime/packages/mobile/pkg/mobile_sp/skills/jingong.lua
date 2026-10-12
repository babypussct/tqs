local jingong = fk.CreateSkill{
  name = "mobile__jingong",
}

Fk:loadTranslationTable{
  ["mobile__jingong"] = "矜功",
  [":mobile__jingong"] = "出牌阶段限一次，你可以将一张装备牌或【杀】当一张锦囊牌使用（从两种随机普通锦囊牌和【美人计】、【笑里藏刀】"..
  "随机一种中三选一），然后本回合结束阶段，若你本回合未造成过伤害，你失去1点体力。",

  ["#mobile__jingong"] = "矜功：你可以将一张装备牌或【杀】当一张锦囊使用",

  ["$mobile__jingong1"] = "首恶不容，余恶亦不轻饶。",
  ["$mobile__jingong2"] = "我以一己之力讨贼匡政。",
}

jingong:addEffect("viewas", {
  anim_type = "control",
  prompt = "#mobile__jingong",
  interaction = function(self, player)
    local names = player:getMark("mobile__jingong-phase")
    if names == 0 then
      names = {"dismantlement", "ex_nihilo", "daggar_in_smile"}
    end
    return UI.CardNameBox {choices = names}
  end,
  handly_pile = true,
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = "slash|.|.|.|.|equip",
  },
  view_as = function(self, player, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = jingong.name
    return card
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(jingong.name, Player.HistoryPhase) == 0
  end,
})

jingong:addEffect(fk.EventPhaseStart, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player.phase == Player.Finish and not player.dead and
      player:usedSkillTimes(jingong.name, Player.HistoryTurn) > 0 and
      #player.room.logic:getActualDamageEvents(1, function (e)
        return e.data.from == player
      end, Player.HistoryTurn) == 0
  end,
  on_use = function (self, event, target, player, data)
    player.room:loseHp(player, 1, jingong.name)
  end,

  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(jingong.name, true) and player.phase == Player.Play
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local names = table.filter(Fk:getAllCardNames("t"), function (name)
      return not Fk:cloneCard(name).is_passive
    end)
    names = room:tableRandomPick(names, 2)
    table.insert(names, room:tableRandomPick({"honey_trap", "daggar_in_smile"}))
    player.room:setPlayerMark(player, "mobile__jingong-phase", names)
  end,
})

return jingong
