local jizhao = fk.CreateSkill{
  name = "jizhao",
  tags = { Skill.Limited },
  related_skills = { "ex__rende" },
}

Fk:loadTranslationTable{
  ["jizhao"] = "激诏",
  [":jizhao"] = "限定技，当你处于濒死状态时，你可将手牌摸至X张（X为你的体力上限），将体力回复至2点，失去〖授钺〗并获得〖仁德〗。",

  ["$jizhao1"] = "仇未报，汉未兴，朕志犹在！",
  ["$jizhao2"] = "王业不偏安，起师再兴汉！",
}

jizhao:addEffect(fk.AskForPeaches, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jizhao.name) and player.dying and player:usedSkillTimes(jizhao.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getHandcardNum() < player.maxHp then
      room:drawCards(player, player.maxHp - player:getHandcardNum(), jizhao.name)
    end
    if player.hp < 2 and not player.dead then
      room:recover{
        who = player,
        num = 2 - player.hp,
        recoverBy = player,
        skillName = jizhao.name,
      }
    end
    room:handleAddLoseSkills(player, "-shouyue|ex__rende", nil)
  end,
})

return jizhao
