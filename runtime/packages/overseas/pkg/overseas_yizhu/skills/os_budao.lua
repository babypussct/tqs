local budao = fk.CreateSkill {
  name = "os__budao",
  tags = { Skill.Limited },
  related_skills = { "os__zhouhu", "os__fengqi", "os__zuhuo", "os__huangjin", "os__guimen", "os__zhouzu", "os__didao" },
}

Fk:loadTranslationTable{
  ["os__budao"] = "布道",
  [":os__budao"] = "限定技，准备阶段，你可以减1点体力上限并回复1点体力，然后你从随机三个<a href='os__budao_skills'>施法技能</a>中选择一个获得之；" ..
  "然后你可以令一名其他角色获得相同技能并交给你一张牌。",

  ["os__budao_skills"] = "<b>咒护</b>: 出牌阶段结束时，你可弃置一张红色手牌，选择一名角色并施法：令其回复X点体力。<br/>" ..
  "<b>丰祈</b>: 出牌阶段结束时，你可弃置一张黑色手牌，选择一名角色并施法：其摸2X张牌。<br/>" ..
  "<b>阻祸</b>: 出牌阶段结束时，你可弃置一张非基本牌并施法：防止你受到的下X次伤害。<br/>" ..
  "<b>黄巾</b>: 锁定技，当你成为【杀】的目标时，你判定：若结果点数与此【杀】点数差值不大于1，则此【杀】对你无效。<br/>" ..
  "<b>鬼门</b>: 锁定技，当你因弃置而失去♠牌后，你判定：若结果点数与你弃置的其中一张♠牌点数差值不大于1，则对一名其他角色造成2点雷电伤害。<br/>" ..
  "<b>咒诅</b>: 出牌阶段限一次，你可选择一名其他角色并施法：令其弃置X张牌，若牌数不足则全部弃置并对其造成1点雷电伤害。<br/>" ..
  "<b>地道</b>: 当一名角色的判定牌生效前，你可打出一张牌替换之，若与原判定牌颜色相同，你摸一张牌。</font>",

  ["#os__budao-ask"] = "布道：选择一个技能获得，然后你可以令一名其他角色获得相同技能并交给你一张牌",
  ["#os__budao-choose"] = "布道：你可以令一名其他角色获得〖%arg〗并交给你一张牌",
  ["#os__budao-give"] = "布道：请交给 %src 一张牌",

  ["$os__budao1"] = "得天之力，从天之道。",
  ["$os__budao2"] = "黄天大道，泽及苍生。",
}

budao:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(budao.name) and player.phase == Player.Start and
      player:usedSkillTimes(budao.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if player.dead then return end
    room:recover{
      who = player,
      num = 1,
      recoverBy = player,
      skillName = budao.name,
    }
    if player.dead then return end
    local skills = room:tableRandomPick(budao.related_skills, 3)
    local sname = room:askToChoice(player, {
      choices = skills,
      skill_name = budao.name,
      prompt = "#os__budao-ask",
      detailed = true,
    })
    room:handleAddLoseSkills(player, sname)
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#os__budao-choose:::" .. sname,
      skill_name = budao.name,
    })
    if #to > 0 then
      to = to[1]
      room:handleAddLoseSkills(to, sname)
      if not to:isNude() then
        local card = room:askToCards(to, {
          min_num = 1,
          max_num = 1,
          skill_name = budao.name,
          prompt = "#os__budao-give:" .. player.id,
          cancelable = false,
        })
        room:moveCardTo(card, Player.Hand, player, fk.ReasonGive, budao.name, nil, false, to)
      end
    end
  end,
})

return budao
