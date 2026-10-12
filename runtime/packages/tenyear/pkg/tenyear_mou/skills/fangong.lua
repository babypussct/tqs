
local fangong = fk.CreateSkill({
  name = "ty__fangong",
  tags = { Skill.Limited },
})

Fk:loadTranslationTable{
  ["ty__fangong"] = "返攻",
  [":ty__fangong"] = "限定技，出牌阶段，你可以回复体力至体力上限并摸五张牌。"..
  "你因〖诱夷〗失去的体力值和牌数的总和每累计达到7后，此技能视为未发动过。",

  ["#ty__fangong"] = "返攻：回复体力至体力上限，摸五张牌",
  ["@ty__fangong"] = "返攻",

  ["$ty__fangong1"] = "伏兵何在！起！",
  ["$ty__fangong2"] = "忍汝数日，便为此时！",
}

fangong:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#ty__fangong",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(fangong.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:setPlayerMark(player, "@ty__fangong", 7)
    if player:isWounded() then
      room:recover{
        who = player,
        num = player.maxHp - player.hp,
        recoverBy = player,
        skillName = fangong.name,
      }
    end
    if player.dead then return end
    player:drawCards(5, fangong.name)
  end,
})

fangong:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@ty__fangong", 0)
end)

return fangong
