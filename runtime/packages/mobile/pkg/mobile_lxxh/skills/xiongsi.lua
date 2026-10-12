local xiongsi = fk.CreateSkill {
  name = "xiongsi",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["xiongsi"] = "凶肆",
  [":xiongsi"] = "限定技，出牌阶段，若你的手牌不少于三张，你可以弃置所有手牌，然后令所有其他角色各失去1点体力。",

  ["#xiongsi"] = "凶肆：你可以弃置所有手牌，令所有其他角色各失去1点体力！",

  ["$xiongsi1"] = "既想杀人灭口，那就同归于尽！",
  ["$xiongsi2"] = "贾充！你不仁就别怪我不义！",
}

xiongsi:addEffect("active", {
  anim_type = "offensive",
  card_num = 0,
  target_num = 0,
  prompt = "#xiongsi",
  can_use = function(self, player)
    return player:usedSkillTimes(xiongsi.name, Player.HistoryGame) == 0 and player:getHandcardNum() > 2 and
      table.find(player:getCardIds("h"), function(id)
        return not player:prohibitDiscard(id)
      end)
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    player:throwAllCards("h")
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not p.dead then
        room:loseHp(p, 1, xiongsi.name)
      end
    end
  end,
})

return xiongsi
