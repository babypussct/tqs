local wufei = fk.CreateSkill {
  name = "wufei",
}

Fk:loadTranslationTable{
  ["wufei"] = "诬诽",
  [":wufei"] = "你使用【杀】或普通锦囊牌造成的伤害的来源视为拥有“雀”的角色。"..
  "当你受到伤害后，若拥有“雀”标记的角色体力值大于3，你可以令其受到1点无来源伤害。",

  ["#wufei-invoke"] = "你可发动 诬诽，令%dest受到1点伤害",

  ["$wufei1"] = "巫蛊实乃凶邪之术，陛下不可不察！",
  ["$wufei2"] = "妾不该多言，只怕陛下为其所害。",
}

local wufeiCanUse = function(player)
  if not player:hasSkill(wufei.name) then return false end
  local mark = player:getMark("yichong_target")
  if type(mark) ~= "table" then return false end
  local to = player.room:getPlayerById(mark[1])
  return to ~= nil and to:isAlive()
end

wufei:addEffect(fk.PreDamage, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if not wufeiCanUse(player) then
      return false
    end

    return player == data.from and player.room.logic:damageByCardEffect()
  end,
  on_cost = function(self, event, target, player, data)
    local mark = player:getMark("yichong_target")
    if type(mark) ~= "table" then return false end
    event:setCostData(self, { tos = { mark[1] } })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.from = room:getPlayerById(event:getCostData(self).tos[1])
    data.by_user = room.logic:damageByCardEffect(true)
  end,
})

wufei:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    if not wufeiCanUse(player) then
      return false
    end

    local to = player.room:getPlayerById(player:getMark("yichong_target")[1])
    return player == target and to.hp > 3
  end,
  on_cost = function(self, event, target, player, data)
    local mark = player:getMark("yichong_target")
    if type(mark) ~= "table" then return false end

    if player.room:askToSkillInvoke(player, { skill_name = wufei.name, prompt = "#wufei-invoke::" .. mark[1] }) then
      event:setCostData(self, { tos = { mark[1] } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:damage{
      to = room:getPlayerById(event:getCostData(self).tos[1]),
      damage = 1,
      skillName = wufei.name,
    }
  end,
})

return wufei
