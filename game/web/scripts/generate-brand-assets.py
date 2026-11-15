#!/usr/bin/env python3
"""Generate locally approved TQS brand variants from a user-supplied illustration.

Usage: python3 generate-brand-assets.py /absolute/path/to/licensed-liu-bei.png /path/to/game/web/public
Requires Pillow. Source art is never copied or embedded in the generator.
"""
import sys, math
from pathlib import Path
from PIL import Image, ImageOps, ImageDraw, ImageFont, ImageFilter, ImageEnhance

if len(sys.argv) != 3:
    raise SystemExit('Usage: generate-brand-assets.py LICENSED_SOURCE_PNG WEB_PUBLIC_DIR')
source=Path(sys.argv[1]); dest=Path(sys.argv[2]); brand=dest/'brand'
if not source.is_file() or not dest.is_dir():
    raise SystemExit('Cannot locate input picture or web public directory')
brand.mkdir(parents=True,exist_ok=True)
original=Image.open(source).convert('RGB')
FONT='/System/Library/Fonts/Avenir Next.ttc'
GOLD=(226,178,81); LIGHT=(255,232,165); DARK=(15,13,14); RED=(139,28,34)

def font(n,idx=0): return ImageFont.truetype(FONT,int(n),index=idx)
def gradient(size,top=(12,13,16),bottom=(41,17,17)):
    im=Image.new('RGBA',size); d=ImageDraw.Draw(im)
    for y in range(size[1]):
        t=y/max(1,size[1]-1);t=t*t*(3-2*t)
        clr=tuple(int(a*(1-t)+b*t) for a,b in zip(top,bottom))+(255,)
        d.line((0,y,size[0],y),fill=clr)
    return im

def frame(d,box,rad=30,border=8):
    d.rounded_rectangle(box,radius=rad,fill=(14,12,15,246),outline=(175,113,40,245),width=border)
    margin=border+11
    d.rounded_rectangle((box[0]+margin,box[1]+margin,box[2]-margin,box[3]-margin),radius=max(5,rad-margin),outline=(255,218,127,140),width=max(2,border//3))

def painted_text(dst,txt,at,sz,stroke=2,spacing=0):
    f=font(sz)
    temp=Image.new('RGBA',dst.size)
    dd=ImageDraw.Draw(temp)
    x,y=at
    if spacing:
        for ch in txt:
            dd.text((x,y),ch,font=f,fill=LIGHT,stroke_width=stroke,stroke_fill=(82,43,19),anchor='lt')
            x+=dd.textlength(ch,font=f)+spacing
    else:
        dd.text(at,txt,font=f,fill=LIGHT,stroke_width=stroke,stroke_fill=(89,43,17),anchor='lt')
    shadow=Image.new('RGBA',dst.size); shadow.paste((0,0,0,140),(0,0,*dst.size))
    alpha=temp.getchannel('A').filter(ImageFilter.GaussianBlur(6))
    shadow.putalpha(alpha)
    dst.alpha_composite(shadow,(0,5)); dst.alpha_composite(temp)

def artwork_fit(size,position=(.5,.5)):
    # Preserve horse and rider proportions; contain rather than warp supplied art.
    return ImageOps.fit(original,size,method=Image.Resampling.LANCZOS,centering=position)

def art_with_soft_edges(dst,rect,fade=60,position=(.5,.47)):
    x,y,w,h=rect
    art=artwork_fit((w,h),position).convert('RGBA')
    mask=Image.new('L',(w,h),255)
    px=mask.load()
    for yy in range(h):
        for xx in range(w):
            edge=min(xx,yy,w-xx-1,h-yy-1)
            px[xx,yy]=min(255, int(255*max(0,edge)/fade))
    dst.paste(art,(x,y),mask)

def medallion(sz,maskable=False):
    canvas=gradient((sz,sz),(11,12,16),(58,23,23))
    d=ImageDraw.Draw(canvas)
    d.ellipse((int(sz*.06),int(sz*.06),int(sz*.94),int(sz*.94)),fill=(80,28,27,255),outline=(222,170,74,255),width=int(sz*.023))
    d.ellipse((int(sz*.095),int(sz*.095),int(sz*.905),int(sz*.905)),fill=(12,12,14,255),outline=(252,220,125,255),width=int(sz*.008))
    inner=(int(sz*.13),int(sz*.12),int(sz*.87),int(sz*.86))
    aw=inner[2]-inner[0];ah=inner[3]-inner[1]
    art=ImageOps.contain(original,(aw,ah),Image.Resampling.LANCZOS)
    # Whole rearing horse and general remain visible in the icon badge.
    tile=gradient((aw,ah),(80,40,30),(17,12,15)).convert('RGB')
    tile.paste(art,((aw-art.width)//2,(ah-art.height)//2))
    mask=Image.new('L',(aw,ah)); m=ImageDraw.Draw(mask)
    m.ellipse((0,0,aw-1,ah-1),fill=255)
    mask=mask.filter(ImageFilter.GaussianBlur(max(1,int(sz*.006))))
    canvas.paste(tile,(inner[0],inner[1]),mask)
    d=ImageDraw.Draw(canvas)
    d.arc((int(sz*.12),int(sz*.11),int(sz*.88),int(sz*.87)),0,360,fill=(245,198,104,255),width=int(sz*.01))
    d.rounded_rectangle((int(sz*.18),int(sz*.725),int(sz*.82),int(sz*.865)),radius=int(sz*.025),fill=(50,13,19,248),outline=(232,173,64,255),width=int(sz*.007))
    f=font(sz*.107)
    box=d.textbbox((0,0),'TQS',font=f,stroke_width=1)
    tw=box[2]-box[0]
    d.text(((sz-tw)/2,int(sz*.738)),'TQS',font=f,fill=LIGHT,stroke_width=1,stroke_fill=(90,48,27))
    # Four small diamonds evoke the four kingdoms, no Chinese characters.
    for deg in (45,135,225,315):
        cx=int(sz*(.5+.445*math.cos(math.radians(deg))))
        cy=int(sz*(.5+.445*math.sin(math.radians(deg))))
        r=max(2,int(sz*.013))
        d.polygon([(cx,cy-r),(cx+r,cy),(cx,cy+r),(cx-r,cy)],fill=GOLD)
    return canvas

# Logo text stays crisp in full-resolution PNG and uses Vietnamese glyphs.
logo=Image.new('RGBA',(1600,440),(0,0,0,0))
icon=medallion(385)
logo.alpha_composite(icon,(20,26))
painted_text(logo,'TAM QUỐC SÁT',(430,74),117,3)
p=ImageDraw.Draw(logo)
p.line((440,246,1514,246),fill=(216,152,65,205),width=4)
p.rounded_rectangle((444,274,790,362),radius=18,fill=(91,18,26,255),outline=(235,177,76,240),width=4)
painted_text(logo,'MOBILE',(473,284),60,1,3)
p.text((829,301),'QUỐC CHIẾN',font=font(45),fill=(222,192,133,255))
logo.save(brand/'logo-horizontal.png',optimize=True)

vertical=gradient((1024,1400),(12,13,17),(45,14,18))
d=ImageDraw.Draw(vertical)
frame(d,(74,47,950,1039),65,13)
art_with_soft_edges(vertical,(106,84,812,916),fade=40)
d=ImageDraw.Draw(vertical)
d.line((112,1011,912,1011),fill=GOLD,width=6)
painted_text(vertical,'TAM QUỐC SÁT',(94,1054),79,2)
d.rounded_rectangle((356,1182,672,1290),radius=17,fill=(91,19,25,255),outline=GOLD,width=5)
painted_text(vertical,'MOBILE',(387,1199),62,1,2)
vertical.convert('RGB').save(brand/'logo-vertical.webp',quality=88,method=6)

hero=original.copy(); hero.thumbnail((900,1200),Image.Resampling.LANCZOS)
hero.save(brand/'liu-bei-white-horse.webp',quality=83,method=6)

portrait=gradient((1080,1920),(12,13,17),(41,12,20))
frame(ImageDraw.Draw(portrait),(57,80,1023,1540),61,12)
art_with_soft_edges(portrait,(85,110,910,1320),fade=60)
painted_text(portrait,'TAM QUỐC SÁT',(89,1534),82,2)
d=ImageDraw.Draw(portrait)
d.rounded_rectangle((363,1683,717,1804),radius=18,fill=(96,20,28,255),outline=GOLD,width=5)
painted_text(portrait,'MOBILE',(402,1704),68,1,1)
portrait.convert('RGB').save(brand/'splash-portrait.webp',quality=83,method=6)

landscape=gradient((1920,1080),(12,13,17),(43,12,20))
frame(ImageDraw.Draw(landscape),(71,66,898,1022),48,11)
art_with_soft_edges(landscape,(93,90,786,907),fade=50)
painted_text(landscape,'TAM QUỐC SÁT',(902,316),87,3)
d=ImageDraw.Draw(landscape)
d.line((928,501,1810,501),fill=GOLD,width=5)
d.rounded_rectangle((1136,562,1594,708),radius=20,fill=(87,18,26,255),outline=GOLD,width=5)
painted_text(landscape,'MOBILE',(1179,587),85,2,2)
landscape.convert('RGB').save(brand/'splash-landscape.webp',quality=84,method=6)

master_icon=medallion(1024).convert('RGB')
master_icon.save(brand/'icon-master-1024.png',optimize=True)
for size,name in [(512,'icon-512.png'),(192,'icon-192.png'),(180,'apple-touch-icon.png')]:
    master_icon.resize((size,size),Image.Resampling.LANCZOS).save(dest/name,optimize=True)
# Android maskable icon: backing extends to all edges, medallion content fits central safe zone.
mask=gradient((512,512),(21,14,18),(84,22,28)).convert('RGB')
small=medallion(410).convert('RGB')
mask.paste(small,(51,51))
mask.save(brand/'icon-maskable-512.png',optimize=True)

# Source-independent vector variant for SVG-first favicon and shareable typographic lockup.
svg='''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 120" role="img" aria-label="Tam Quốc Sát Mobile">
<defs><linearGradient id="g" x2=".8" y2="1"><stop stop-color="#ffe5a0"/><stop offset=".55" stop-color="#d4af37"/><stop offset="1" stop-color="#996122"/></linearGradient></defs>
<rect x="2" y="2" width="116" height="116" rx="26" fill="#100e0c" stroke="url(#g)" stroke-width="4"/>
<path d="M60 12 102 37 96 86 60 110 24 86 18 37Z" fill="#4f161d" stroke="url(#g)" stroke-width="3"/>
<path d="M42 24Q60 16 78 24L83 44 60 55 37 44Z" fill="#edca7c" opacity=".95"/>
<path d="M44 30V45M60 23V51M76 30V45" stroke="#6d2820" stroke-width="4"/>
<path d="M37 57Q60 45 83 57L77 90Q60 99 43 90Z" fill="#18131a" stroke="#d4af37" stroke-width="2"/>
<text x="60" y="79" text-anchor="middle" font-family="Arial,sans-serif" font-size="27" font-weight="900" fill="url(#g)">TQS</text>
</svg>'''
(dest/'favicon.svg').write_text(svg,encoding='utf-8')
# Transparent typographic SVG, suitable when the illustration cannot be licensed to publish.
word='''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 280" role="img" aria-label="Tam Quốc Sát Mobile">
<defs><linearGradient id="gold" x2="0.2" y2="1"><stop stop-color="#ffe5a0"/><stop offset=".55" stop-color="#d4af37"/><stop offset="1" stop-color="#976122"/></linearGradient></defs>
<path d="M125 12 233 70 222 194 125 261 28 194 17 70Z" fill="#42151a" stroke="url(#gold)" stroke-width="10"/>
<path d="M81 74Q125 27 169 74L158 116 125 131 92 116Z" fill="url(#gold)"/>
<path d="M80 155 125 137 170 155 163 206 125 235 87 206Z" fill="#100e0c" stroke="#d4af37" stroke-width="4"/>
<text x="125" y="191" text-anchor="middle" font-family="Be Vietnam Pro,Arial,sans-serif" font-size="47" font-weight="900" fill="url(#gold)">TQS</text>
<text x="275" y="120" font-family="Be Vietnam Pro,Arial,sans-serif" font-weight="900" font-size="83" fill="url(#gold)">TAM QUỐC SÁT</text>
<path d="M280 147H959" stroke="#d4af37" stroke-width="4"/>
<rect x="280" y="171" width="307" height="79" rx="13" fill="#6e1721" stroke="#d4af37" stroke-width="3"/>
<text x="305" y="227" font-family="Be Vietnam Pro,Arial,sans-serif" font-weight="800" font-size="57" fill="#ffe5a0">MOBILE</text>
</svg>'''
(brand/'logo-horizontal.svg').write_text(word,encoding='utf-8')
for p in sorted([*brand.iterdir(), dest/'favicon.svg',dest/'icon-192.png',dest/'icon-512.png',dest/'apple-touch-icon.png']):
    print(p.relative_to(dest),p.stat().st_size)
