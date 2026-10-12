local geyuan = fk.CreateSkill {
  name = "mobile__geyuan",
}

Fk:loadTranslationTable{
  ["mobile__geyuan"] = "割圆",
  [":mobile__geyuan"] = "当你使用点数为X的牌时（X为圆周率中小数点后第一位的值），你可以摸Y张牌并调整X为下一位的值" ..
  "（Y为你本回合发动此技能的次数+1，且至多为π）。",

  ["@mobile__geyuan_record-noclear"] = "割圆",
  ["#mobile__geyuan-invoke"] = "割圆：你可以摸%arg张牌",

  ["$mobile__geyuan1"] = "割之弥细，所失弥少，以至不可割。",
  ["$mobile__geyuan2"] = "周径为至然之数，非周三径一之律也。",
}

geyuan.piStr = "1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421" ..
"170679821480865132823066470938446095505822317253594081284811174502841027019385211055596446229489549303819644288" ..
"109756659334461284756482337867831652712019091456485669234603486104543266482133936072602491412737245870066063155" ..
"881748815209209628292540917153643678925903600113305305488204665213841469519415116094330572703657595919530921861" ..
"173819326117931051185480744623799627495673518857527248912279381830119491298336733624406566430860213949463952247" ..
"371907021798609437027705392171762931767523846748184676694051320005681271452635608277857713427577896091736371787" ..
"214684409012249534301465495853710507922796892589235420199561121290219608640344181598136297747713099605187072113" ..
"499999983729780499510597317328160963185950244594553469083026425223082533446850352619311881710100031378387528865" ..
"875332083814206171776691473035982534904287554687311595628638823537875937519577818577805321712268066130019278766" ..
"111959092164201989380952572010654858632788659361533818279682303019520353018529689957736225994138912497217752834" ..
"791315155748572424541506959508295331168617278558890750983817546374649393192550604009277016711390098488240128583" ..
"616035637076601047101819429555961989467678374494482553797747268471040475346462080466842590694912933136770289891" ..
"521047521620569660240580381501935112533824300355876402474964732639141992726042699227967823547816360093417216412" ..
"199245863150302861829745557067498385054945885869269956909272107975093029553211653449872027559602364806654991198" ..
"818347977535663698074265425278625518184175746728909777727938000816470600161452491921732172147723501414419735685" ..
"481613611573525521334757418494684385233239073941433345477624168625189835694855620992192221842725502542568876717" ..
"904946016534668049886272327917860857843838279679766814541009538837863609506800642251252051173929848960841284886" ..
"269456042419652850222106611863067442786220391949450471237137869609563643719172874677646575739624138908658326459" ..
"9581339047802759009"

geyuan.toNextPiNumber = function(player)
  local pos = math.max(1, player:getMark("mobile__geyuan_pos-noclear"))
  pos = pos + 1
  if pos > #geyuan.piStr then
    pos = 1
  end

  local tip = "<font color='red'><strong>" .. geyuan.piStr[pos] .. "</strong></font>"
  local tempPos = pos
  for _ = 1, 3 do
    tempPos = tempPos + 1
    if tempPos > #geyuan.piStr then
      tempPos = 1
    end

    tip = tip .. geyuan.piStr[tempPos]
  end

  player.room:setPlayerMark(player, "@mobile__geyuan_record-noclear", tip)
  player.room:setPlayerMark(player, "mobile__geyuan_pos-noclear", pos)
end

geyuan:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player, data)
    local currentNumber = tonumber(geyuan.piStr[math.max(1, player:getMark("mobile__geyuan_pos-noclear"))])

    return
      target == player and
      (
        data.card.number == currentNumber or
        (data.card.number >= 10 and currentNumber == 0 and player:hasSkill("chongcha"))
      ) and
      player:hasSkill(geyuan.name)
  end,
  on_cost = function(self, event, target, player, data)
    local drawNum = math.min(3, player:usedSkillTimes(geyuan.name) + 1)
    if player.room:askToSkillInvoke(
      player,
      {
        skill_name = geyuan.name,
        prompt = "#mobile__geyuan-invoke:::" .. drawNum,
      }
    ) then
      event:setCostData(self, { drawNum = drawNum })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(event:getCostData(self).drawNum, geyuan.name)
    geyuan.toNextPiNumber(player)
  end,
})

geyuan:addAcquireEffect(function(self, player)
  local tip = "<font color='red'><strong>" .. geyuan.piStr[1] .. "</strong></font>" .. geyuan.piStr:sub(2, 4)
  player.room:setPlayerMark(player, "@mobile__geyuan_record-noclear", tip)
  player.room:setPlayerMark(player, "mobile__geyuan_pos-noclear", 1)
end)

geyuan:addLoseEffect(function (self, player, isDeath)
  if not isDeath then
    player.room:setPlayerMark(player, "@mobile__geyuan_record-noclear", 0)
    player.room:setPlayerMark(player, "mobile__geyuan_pos-noclear", 0)
  end
end)

return geyuan
