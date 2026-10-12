local os__daming = fk.CreateSkill {
  name = "os__daming",
  attached_skill_name = "os__daming_other&",
}

Fk:loadTranslationTable{
  ["os__daming"] = "达命",
  [":os__daming"] = "①游戏开始时，你获得3点“达命”值；②其他角色的出牌阶段限一次，其可以交给你一张牌，然后你选择另一名其他角色。若后者有相同类型的牌，"..
  "则后者须交给前者一张相同类型的牌且你获得1点“达命”值，否则你将以此法获得的牌交给前者。",

  ["@os__daming"] = "达命",


  ["$os__daming1"] = "吾之伯乐，吾自为公之良骥。",
  ["$os__daming2"] = "宣军奉使，识遇日加。",
}

local changeOsDaming = function (player, n)
  local room = player.room
  local mark = type(player:getMark("@os__daming")) == "string" and 0 or player:getMark("@os__daming")
  mark = mark + n
  room:setPlayerMark(player, "@os__daming", mark == 0 and "0" or mark)
end

os__daming:addEffect(fk.GameStart, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(os__daming.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    changeOsDaming(player, 3)
  end,
})

return os__daming
