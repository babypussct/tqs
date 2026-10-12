local jugu = fk.CreateSkill{
  name = "ofl_heg__jugu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ofl_heg__jugu"] = "巨贾",
  [":ofl_heg__jugu"] = "锁定技，当你明置此武将牌后，你摸X张牌，手牌上限+X（X为你的体力上限）。",

  ["$ofl_heg__jugu1"] = "钱？要多少有多少。",
  ["$ofl_heg__jugu2"] = "君子爱财，取之有道。",
}

jugu:addEffect(fk.GeneralRevealed, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    if target == player and player:hasSkill(jugu.name) then
      for _, v in pairs(data) do
        if table.contains(Fk.generals[v]:getSkillNameList(), jugu.name) then return true end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, MarkEnum.AddMaxCards, player.maxHp)
    player:drawCards(player.maxHp, jugu.name)
  end,
})

return jugu
