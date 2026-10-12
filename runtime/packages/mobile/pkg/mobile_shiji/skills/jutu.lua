local jutu = fk.CreateSkill {
  name = "jutu",
  derived_piles = "liuzhang_sheng",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jutu"] = "据土",
  [":jutu"] = "锁定技，准备阶段，你获得所有所有的“生”，摸X+1张牌，然后将X张牌置于你的武将牌上，称为“生”（X为你〖邀虎〗选择势力的角色数）。",

  ["liuzhang_sheng"] = "生",
  ["#jutu-put"] = "据土：请将%arg张牌置为“生”",

  ["$jutu1"] = "百姓安乐足矣，穷兵黩武实不可取啊。",
  ["$jutu2"] = "内乱初定，更应休养生息。",
}

jutu:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jutu.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #player:getPile("liuzhang_sheng") > 0 then
      room:obtainCard(player, player:getPile("liuzhang_sheng"), false, fk.ReasonJustMove, player, jutu.name)
    end
    if player.dead then return end
    if player:getMark("@yaohu") == 0 then
      player:drawCards(1, jutu.name)
    else
      local n = #table.filter(room.alive_players, function(p)
        return p.kingdom == player:getMark("@yaohu")
      end)
      player:drawCards(n + 1, jutu.name)
      if not player.dead and not player:isNude() then
        local cards = player:getCardIds("he")
        if #cards > n then
          cards = room:askToCards(player, {
            min_num = n,
            max_num = n,
            include_equip = true,
            skill_name = jutu.name,
            prompt = "#jutu-put:::"..n,
            cancelable = false,
          })
        end
        player:addToPile("liuzhang_sheng", cards, true, jutu.name)
      end
    end
  end,
})

return jutu
