local shouyue = fk.CreateSkill{
  name = "shouyue",
  tags = {Skill.Compulsory},
}
shouyue:addEffect(fk.GeneralRevealed, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(shouyue.name, true) then
      for _, v in pairs(data) do
        if table.contains(Fk.generals[v]:getSkillNameList(), shouyue.name) then return true end
      end
    end
  end,
})

Fk:loadTranslationTable{
  ["shouyue"] = "授钺",
  [":shouyue"] = "<b><font color='goldenrod'>君主技</font></b>，你拥有“五虎将大旗”。<br>" ..
    "#<b>五虎将大旗</b>：存活的蜀势力角色拥有的〖武圣〗〖咆哮〗〖龙胆〗〖铁骑〗〖烈弓〗分别按以下规则修改：<br>" ..
    "〖武圣〗：将“红色牌”改为“任意牌”；<br>"..
    "〖咆哮〗：增加描述“当你使用杀指定目标后，此【杀】无视其他角色的防具”；<br>"..
    "〖龙胆〗：增加描述“当你使用/打出因〖龙胆〗转化的普【杀】或【闪】时，你摸一张牌”；<br>"..
    "〖铁骑〗：将“一张明置的武将牌的非锁定技失效”改为“所有明置的武将牌的非锁定技失效”；<br>"..
    "〖烈弓〗：增加描述“你的攻击范围+1”。",
  ["$shouyue"] = "布德而昭仁，见旗如见朕!",
}

return shouyue
