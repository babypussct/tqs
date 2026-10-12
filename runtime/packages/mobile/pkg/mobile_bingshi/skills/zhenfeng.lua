local zhenfeng = fk.CreateSkill{
  name = "mobile__zhenfeng",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["mobile__zhenfeng"] = "振锋",
  [":mobile__zhenfeng"] = "限定技，出牌阶段，你可以选择一项：1.回复2点体力；2.分别修改〖酣战〗及〖战烈〗中的X为当前体力值、" ..
  "已损失体力值、存活角色数中的一项（拥有对应技能方可选择）。",

  ["#mobile__zhenfeng"] = "振锋：你可以回复体力或修改其他技能",
  ["mobile__zhenfeng_recover"] = "回复2点体力",
  ["mobile__zhenfeng_upgrade"] = "修改技能",

  ["mobile__zhenfeng_hp"] = "当前体力值",
  ["mobile__zhenfeng_lostHp"] = "已损失体力值",
  ["mobile__zhenfeng_alives"] = "存活角色数",
  ["#mobile__zhenfeng-choose"] = "振锋：请将“%arg”中的X修改为其中一项",
  ["@mobile__zhenfeng_mobile__hanzhan"] = "酣战",
  ["@mobile__zhenfeng_zhanlie"] = "战烈",

  ["$mobile__zhenfeng1"] = "有胆气者，随某前去一战！",
  ["$mobile__zhenfeng2"] = "待吾重振兵马，胜负犹未可知！",
  ["$mobile__zhenfeng3"] = "前番未见高下，此番定决生死！",
  ["$mobile__zhenfeng4"] = "天道择义而襄，英雄待机而胜！",
}

zhenfeng:addEffect("active", {
  anim_type = "support",
  prompt = "#mobile__zhenfeng",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(zhenfeng.name, Player.HistoryGame) == 0 and
      (player:isWounded() or (player:hasSkill("mobile__hanzhan", true) or player:hasSkill("zhanlie", true)))
  end,
  interaction = function(self, player)
    local choices = {}
    if player:isWounded() then
      table.insert(choices, "mobile__zhenfeng_recover")
    end
    if player:hasSkill("mobile__hanzhan", true) or player:hasSkill("zhanlie", true) then
      table.insert(choices, "mobile__zhenfeng_upgrade")
    end
    return UI.ComboBox { choices = choices, all_choices = { "mobile__zhenfeng_recover", "mobile__zhenfeng_upgrade" } }
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    if self.interaction.data == "mobile__zhenfeng_recover" then
      room:recover{
        who = player,
        num = 2,
        recoverBy = player,
        skillName = zhenfeng.name,
      }
    else
      for _, skill in ipairs({ "mobile__hanzhan", "zhanlie" }) do
        if player:hasSkill(skill, true) then
          local choice = room:askToChoice(player, {
            choices = { "mobile__zhenfeng_hp", "mobile__zhenfeng_lostHp", "mobile__zhenfeng_alives" },
            skill_name = zhenfeng.name,
            prompt = "#mobile__zhenfeng-choose:::"..skill,
          })
          room:setPlayerMark(player, "@mobile__zhenfeng_"..skill, choice)
        end
      end
    end
  end,
})

return zhenfeng
