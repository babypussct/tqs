
local chijian = fk.CreateSkill {
  name = "chijian",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["chijian"] = "持剑",
  [":chijian"] = "锁定技，你出牌阶段可使用【杀】次数+1，若你装备区没有武器牌，你视为装备【青釭剑】。",

  ["$chijian1"] = "嘎达！他赵云算个屁！出来混要讲实力！",
  ["$chijian2"] = "嘎达！这叫大青釭！寻常人可背不起！",
}

chijian:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chijian.name) and
      #player:getEquipments(Card.SubtypeWeapon) == 0 and
      data.card and data.card.trueName == "slash" and not data.to.dead and
      Fk.skills["#qinggang_sword_skill"]:isEffectable(player)
  end,
  on_use = function (self, event, target, player, data)
    Fk.skills["#qinggang_sword_skill"]:doCost(event, target, player, data)
  end,
})

chijian:addEffect("atkrange", {
  fixed_func = function (self, from)
    if from:hasSkill(chijian.name) and #from:getEquipments(Card.SubtypeWeapon) == 0 then
      return 2
    end
  end,
})

chijian:addEffect("targetmod", {
  residue_func = function (self, player, skill, scope, card, to)
    if player:hasSkill(chijian.name) and card and card.trueName == "slash" then
      return 1
    end
  end,
})

return chijian
