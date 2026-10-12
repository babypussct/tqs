local shenwei = fk.CreateSkill{
  name = "ty_heg__shenwei",
  tags = { Skill.MainPlace },
}

Fk:loadTranslationTable{
  ["ty_heg__shenwei"] = "神威",
  [":ty_heg__shenwei"] = "主将技，此武将牌上单独的阴阳鱼个数-1。摸牌阶段，你额外摸两张牌，你的手牌上限+2。",

  ["$ty_heg__shenwei1"] = "锋镝鸣手中，锐戟映秋霜。",
  ["$ty_heg__shenwei2"] = "红妆非我愿，学武觅封侯。",
}

shenwei:addEffect(fk.DrawNCards, {
  anim_type = "drawcard",
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.n = data.n + 2
  end,
})

shenwei:addEffect("maxcards", {
  fixed_func = function(self, player)
    if player:hasShownSkill(shenwei.name) then
      return player.hp + 2
    end
  end
})

return shenwei
