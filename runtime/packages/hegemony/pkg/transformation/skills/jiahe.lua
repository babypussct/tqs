local jiahe = fk.CreateSkill{
  name = "jiahe",
  derived_piles = "lord_fenghuo",
  tags = {Skill.Compulsory},
  related_skills = { "ld__lordsunquan_yingzi", "ld__lordsunquan_haoshi", "ld__lordsunquan_shelie", "ld__lordsunquan_duoshi" }
}

Fk:loadTranslationTable{
  ["jiahe"] = "嘉禾",
  [":jiahe"] = "<b><font color='goldenrod'>君主技</font></b>，你拥有“缘江烽火图”。<br>" ..
    "#<b>缘江烽火图</b>：①吴势力角色出牌阶段限一次，其可将一张装备牌置于“缘江烽火图”上，称为“烽火”。<br>" ..
    "②吴势力角色的准备阶段，其可根据“烽火”数量选择获得对应的技能直至其回合结束：<br>"..
    "不小于一，〖英姿〗；不小于二，〖好施〗；不小于三，〖涉猎〗；不小于四，〖度势〗；不小于五，可额外选择一项。<br>"..
    "③锁定技，当你受到【杀】或锦囊牌造成的伤害后，你将一张“烽火”置入弃牌堆。",

  ["$jiahe"] = "嘉禾生，大吴兴！",
}
jiahe:addEffect(fk.GeneralRevealed, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    if target == player and player:hasSkill(jiahe.name, true) then
      for _, v in pairs(data) do
        if table.contains(Fk.generals[v]:getSkillNameList(), jiahe.name) then return true end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    player.room:handleAddLoseSkills(player, '#fenghuotu')
  end,
})

return jiahe
