
local hengzheng = fk.CreateSkill{
  name = "hengzheng",
}

Fk:loadTranslationTable{
  ["hengzheng"] = "横征",
  [":hengzheng"] = "摸牌阶段，若你体力值为1或者没有手牌，你可以改为获得所有其他角色区域内各一张牌。",

  ["#hengzheng-invoke"] = "横征：是否放弃摸牌，改为获得所有其他角色区域内各一张牌？",

  ["$hengzheng1"] = "老夫进京平乱，岂能空手而归？",
  ["$hengzheng2"] = "谁的？都是我的！",
}

hengzheng:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(hengzheng.name) and player.phase == Player.Draw and
      (player.hp == 1 or player:isKongcheng()) and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return not p:isAllNude()
      end) and not data.phase_end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = hengzheng.name,
      prompt = "#hengzheng-invoke",
    }) then
      event:setCostData(self, { tos = room:getOtherPlayers(player) })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.phase_end = true
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not p:isAllNude() then
        local card = room:askToChooseCard(player, {
          target = p,
          flag = "hej",
          skill_name = hengzheng.name,
        })
        room:obtainCard(player, card, false, fk.ReasonPrey, player, hengzheng.name)
        if player.dead then return end
      end
    end
  end,
})

return hengzheng
