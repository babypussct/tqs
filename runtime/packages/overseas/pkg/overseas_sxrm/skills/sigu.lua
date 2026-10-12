local sigu = fk.CreateSkill {
  name = "os__sigu",
}

Fk:loadTranslationTable{
  ["os__sigu"] = "似故",
  [":os__sigu"] = "出牌阶段限一次，你可以令一名其他角色进行一次判定，然后对其造成两次1点伤害，期间其根据判定结果获得对应的"..
  "<a href='os__sigu_skills'>“受到伤害后”技能</a>。",

  ["os__sigu_skills"] = "A <a href=':zhichi'>智迟</a>  2 <a href=':ex__ganglie'>刚烈</a>  3 <a href=':fankui'>反馈</a><br>"..
  "4 <a href=':yiji'>遗计</a>  5 <a href=':ol_ex__jieming'>节命</a>  6 <a href=':fangzhu'>放逐</a><br>"..
  "7 <a href=':shibei'>矢北</a>  8 <a href=':chengxiang'>称象</a>  9 <a href=':zhiyu'>智愚</a><br>"..
  "10 <a href=':jilei'>鸡肋</a>  J <a href=':ty__benyu'>贲育</a>  Q <a href=':chouce'>筹策</a><br>"..
  "K <a href=':wuhun'>武魂</a><br>",

  ["#os__sigu"] = "似故：令一名角色判定，对其造成两次1点伤害，在此期间其拥有一个“受到伤害后”技能",

  ["$os__sigu1"] = "叹诸君先孤而死，然孤先诸君而凋。",
  ["$os__sigu2"] = "往昔逝者如斯，梦里纷至沓来！",
  ["$os__sigu3"] = "昔孤以不疑待公台，故招无妄之祸。（智迟）",
  ["$os__sigu4"] = "元让若终无愧于孤，何需窃汉官之嫌？（刚烈）",
  ["$os__sigu5"] = "孤尝梦三马同槽而食之，仲达可解何意？（反馈）",
  ["$os__sigu6"] = "奉孝之计，成则成矣，败则孤万劫不复！（遗计）",
  ["$os__sigu7"] = "孤与文若同路而来，奈何君竟弃孤先去！（节命）",
  ["$os__sigu8"] = "子桓恒以伪心对孤，孤知此亦为诚也！（放逐）",
  ["$os__sigu9"] = "公与徒言尽忠于北，不过垂死以搏孤怜尔！（矢北）",
  ["$os__sigu10"] = "仓舒尚幼便破衣蔽孤，及长又将何为？（称象）",
  ["$os__sigu11"] = "公达与孤帐中秘策，岂欲传之后世？（智愚）",
  ["$os__sigu12"] = "德祖欲假孤以显其才，孤岂会令之如愿？（鸡肋）",
  ["$os__sigu13"] = "仲德有捧日之兆，能成大业，何甘屈身侍孤？（贲育）",
  ["$os__sigu14"] = "志才许孤山河功业，然竟殒身负孤！（筹策）",
  ["$os__sigu15"] = "孤独不疑云长之忠义，只恨公忠不在孤！（武魂）",
}

sigu:addEffect("active", {
  anim_type = "offensive",
  prompt = "#os__sigu",
  audio_index = {1, 2},
  can_use = function(self, player)
    return player:usedSkillTimes(sigu.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local judge = {
      who = target,
      reason = sigu.name,
      pattern = ".|1~13",
    }
    room:judge(judge)
    if target.dead then return end
    local skill
    local index = judge.card.number
    if index > 0 and index < 14 then
      local skills = {
        "zhichi", "ex__ganglie", "fankui", "yiji",
        "ol_ex__jieming", "fangzhu", "shibei", "chengxiang",
        "zhiyu", "jilei", "ty__benyu", "chouce", "wuhun"
      }
      player:broadcastSkillInvoke("os__sigu", index + 2)
      if not target:hasSkill(skills[index], true) then
        skill = skills[index]
        room:handleAddLoseSkills(target, skill)
      end
    end
    for _ = 1, 2 do
      if target.dead then return end
      if not player.dead then
        room:damage{
          from = player,
          to = target,
          damage = 1,
          skillName = sigu.name,
        }
      end
    end
    if skill then
      room:handleAddLoseSkills(target, "-"..skill)
    end
  end,
})

return sigu
