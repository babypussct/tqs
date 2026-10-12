local daming = fk.CreateSkill {
  name = "daming",
  attached_skill_name = "daming_other&",
}

Fk:loadTranslationTable{
  ["daming"] = "达命",
  [":daming"] = "①游戏开始时，你获得1点“达命”值；②其他角色的出牌阶段限一次，其可以交给你一张牌，然后你选择另一名其他角色。若后者有相同类型的牌，"..
  "则后者须交给前者一张相同类型的牌且你获得1点“达命”值，否则你将以此法获得的牌交给前者。",

  ["@daming"] = "达命",

  ["$daming1"] = "幸蒙士元斟酌，诣公于葭萌，达命于蜀川。",
  ["$daming2"] = "论治图王，助吾主成就大业。",
  ["$daming3"] = "心大志广，愧公知遇之恩。",
}

local changeDaming = function (player, n)
  local room = player.room
  local mark = type(player:getMark("@daming")) == "string" and 0 or player:getMark("@daming")
  mark = mark + n
  room:setPlayerMark(player, "@daming", mark == 0 and "0" or mark)
end

daming:addEffect(fk.GameStart, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(daming.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    changeDaming(player, 1)
  end,
})

return daming
