"""Mahjong Rise / ONE MORE PAIR — deterministic 15 s motion graphic.

Run: python promo/render_15s.py [--preview]
Assets belong to the game. Music and sound design are synthesized here.
"""
from pathlib import Path
import math
import sys
import wave
import subprocess
from functools import lru_cache
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'promo' / 'Mahjong-Rise-15s.mp4'
BUILD = ROOT / 'promo' / '15s-build'
FFMPEG = Path(r'C:\Users\Main\AppData\Local\Programs\Python\Python312\Lib\site-packages\imageio_ffmpeg\binaries\ffmpeg-win-x86_64-v7.1.exe')
W, H, FPS, DUR = 1080, 1920, 30, 15
B = 15 / 32
CREAM = '#FFF6DD'
LIME = '#D9FF68'
DARK = '#07291F'
FONT = r'C:\Windows\Fonts\arialbd.ttf'
REG = r'C:\Windows\Fonts\segoeui.ttf'

def clamp(x): return max(0., min(1., x))
def prog(t,a,b): return clamp((t-a)/(b-a))
def ease(x): return 1-(1-clamp(x))**3
def back(x):
    x=clamp(x)-1
    return 1+2.70158*x**3+1.70158*x*x
def mix(a,b,p): return a+(b-a)*p

def load(path):
    im=Image.open(ROOT / path).convert('RGBA')
    box=im.getchannel('A').getbbox()
    return im.crop(box) if box else im

def fit(im,w=None,h=None):
    if h is not None: w=round(im.width*h/im.height)
    else: h=round(im.height*w/im.width)
    return im.resize((max(1,int(w)),max(1,int(h))),Image.Resampling.LANCZOS)

def place(c,im,x,y,scale=1,angle=0,alpha=1):
    if scale<.005 or alpha<.005: return
    if abs(scale-1)>.002: im=fit(im,w=round(im.width*scale))
    if angle: im=im.rotate(angle,Image.Resampling.BICUBIC,expand=True)
    if alpha<.999:
        im=im.copy(); im.putalpha(im.getchannel('A').point(lambda a: round(a*clamp(alpha))))
    c.alpha_composite(im,(round(x-im.width/2),round(y-im.height/2)))

@lru_cache(None)
def text(s,size,color=CREAM,font=FONT):
    f=ImageFont.truetype(font,size)
    box=f.getbbox(s)
    im=Image.new('RGBA',(box[2]-box[0]+20,box[3]-box[1]+20))
    ImageDraw.Draw(im).text((10-box[0],10-box[1]),s,font=f,fill=color)
    return im

def title(c,s,y,size=110,color=CREAM,t=1,delay=0,angle=0,x=515):
    p=back(prog(t,delay,delay+.30))
    im=text(s,size,color)
    sc=min(900/im.width,1)*max(.001,p)
    place(c,im,x,y+65*(1-clamp(p)),sc,angle,prog(t,delay,delay+.12))

def label(c,s,y,color=LIME,size=28,x=515): place(c,text(s,size,color,REG),x,y)

def tile(idx):
    im=Image.new('RGBA',(184,234))
    d=ImageDraw.Draw(im)
    d.rounded_rectangle((8,12,181,231),28,fill='#A38C53')
    d.rounded_rectangle((2,2,175,219),28,fill='#E9D5A4')
    d.rounded_rectangle((2,2,175,206),25,fill='#FFF8E7')
    d.rounded_rectangle((9,8,169,201),20,outline='#FFFFFF',width=3)
    glyph=fit(load(f'assets/titles/fruit/{idx+1:02d}.png'),w=124)
    place(im,glyph,88,107)
    return im

TILES=[tile(i) for i in range(12)]
HOUSES=[fit(load(f'assets/courtyard/builds/house/{i:02d}.png'),h=h) for i,h in [(3,410),(10,530),(17,620),(24,735)]]
PETS=[fit(load('assets/pets/'+s+'.png'),h=430) for s in ['fox','cat','dog','raccoon','hamster']]
ICON=fit(load('store/play-icon-512.png'),w=290)
mask=Image.new('L',ICON.size)
ImageDraw.Draw(mask).rounded_rectangle((0,0,289,289),64,fill=255)
ICON.putalpha(mask)

yy,xx=np.mgrid[0:H,0:W].astype(np.float32)
r=np.sqrt(((xx-500)/980)**2+((yy-930)/1600)**2)
g=np.maximum(0,1-r)**2
arr=np.empty((H,W,3),dtype=np.uint8)
for i,(base,add) in enumerate([(4,17),(26,60),(23,30)]): arr[:,:,i]=base+g*add
BG=Image.fromarray(arr).convert('RGBA')
del xx,yy,r,g,arr

def background(t,light=False):
    c=Image.new('RGBA',(W,H),LIME) if light else BG.copy()
    d=ImageDraw.Draw(c)
    col='#C7EA5D' if light else '#194D38'
    for k in range(5):
        rad=220+k*215+25*math.sin(t*.8)
        d.ellipse((510-rad,990-rad,510+rad,990+rad),outline=col,width=2)
    for k in range(22):
        x=(k*347+37*math.sin(t+k))%W
        y=(k*281-t*(22+k%5*9))%H
        s=2+k%3
        d.ellipse((x-s,y-s,x+s,y+s),fill=col if light else '#91A96A')
    return c

def burst(c,x,y,p,color=LIME):
    if not 0<p<1:return
    d=ImageDraw.Draw(c)
    for k in range(16):
        a=k*math.tau/16+.1
        r=60+ease(p)*260
        r2=r+50*(1-p)
        d.line((x+math.cos(a)*r,y+math.sin(a)*r,x+math.cos(a)*r2,y+math.sin(a)*r2),fill=color,width=max(1,round(8*(1-p))))

def pill(c,s,x,y,w=390,color=LIME,fg=DARK):
    im=Image.new('RGBA',(w,76))
    ImageDraw.Draw(im).rounded_rectangle((0,0,w-1,75),38,fill=color)
    place(im,text(s,30,fg),w/2,38)
    place(c,im,x,y)

def hook(c,t):
    # Immediate full-size hook; individual words hit successive eighth notes.
    label(c,'MAHJONG RISE',220)
    title(c,'ЕЩЁ',460,182,t=t+.18,angle=-3)
    title(c,'ОДНУ',655,182,LIME,t=t,delay=.16,angle=2)
    title(c,'ПАРУ?',852,182,t=t,delay=.34,angle=-2)
    meet=ease(prog(t,.35,1.16))
    for j in range(2):
        x=mix(-170 if j==0 else 1240,360 if j==0 else 666,meet)
        place(c,TILES[0],x,1240+18*math.sin(t*6+j),1.58,(1-meet)*(-65 if j==0 else 65)+(-12 if j==0 else 12))
    burst(c,515,1240,prog(t,1.10,1.65))
    if t>.88: pill(c,'ЛАДНО. ПОСЛЕДНЮЮ.',515,1580,530)

# A paired layered board, followed by pair-to-tray flights.
LAY=[]
for row in range(4):
    for col in range(4): LAY.append([290+col*149,695+row*178,(row*2+col//2)%12,0])
LAY.extend([[435,860,2,1],[584,860,2,1],[435,1038,5,1],[584,1038,5,1]])
MATCH=[(16,17,.70),(18,19,1.42),(0,3,2.14)]
LAY[3][2]=LAY[0][2]
LAY[1][2]=LAY[2][2]

def board(c,t):
    title(c,'СОБИРАЙ.',390,132,t=t)
    label(c,'НАХОДИ ПАРЫ. ОСВОБОЖДАЙ ПОЛЕ.',510,size=29)
    d=ImageDraw.Draw(c)
    d.rounded_rectangle((213,1380,817,1548),34,fill='#06271E',outline='#6C8E58',width=3)
    for j in range(4):
        x=231+j*143
        d.rounded_rectangle((x,1396,x+131,1532),19,outline='#46633F',width=2)
    for i,(x,y,idx,layer) in enumerate(LAY):
        p=back(prog(t,.025*(i%5),.025*(i%5)+.40))
        sc=.76*p; a=1
        y-=layer*9
        for aidx,bidx,start in MATCH:
            if i not in (aidx,bidx): continue
            f=ease(prog(t,start,start+.32))
            x=mix(x,296 if i==aidx else 439,f)
            y=mix(y,1464,f)-150*math.sin(f*math.pi)
            sc*=mix(1,.74,f)
            gone=prog(t,start+.42,start+.61)
            sc*=1+.35*gone; a=1-gone
        place(c,TILES[idx],x,y,sc,alpha=a)
    for k,(_,_,start) in enumerate(MATCH):
        p=prog(t,start+.40,start+.88)
        burst(c,368,1464,p)
        if 0<p<1: place(c,text('ПАРА!',60,LIME),515,1320-70*p,1,alpha=1-p)
    label(c,'НАХОДИ СВОЙ РИТМ',1650,size=33)

def yard(c,t):
    title(c,'СТРОЙ.',370,156,DARK,t=t)
    label(c,'КАЖДАЯ ПОБЕДА — ШАГ ВПЕРЁД',500,DARK,30)
    stage=min(3,int(max(0,t-.18)/.58))
    local=max(0,t-.18-stage*.58)
    sc=.90+.1*back(prog(local,0,.28))
    # Clean platform under the actual evolving house art.
    d=ImageDraw.Draw(c)
    d.ellipse((110,1170,920,1410),fill='#B0D650')
    d.ellipse((160,1200,870,1370),fill='#91B448')
    house=HOUSES[stage]
    place(c,house,515,1300-house.height*sc/2,sc)
    burst(c,515,1000,prog(local,.05,.45),DARK)
    pill(c,'ТВОЙ ДВОР РАСТЁТ',515,1510,580,DARK,CREAM)
    for i in range(4):
        d.rounded_rectangle((304+i*112,1620,398+i*112,1632),6,fill=DARK if i<=stage else '#ADCD53')

def pets(c,t):
    title(c,'ЗАЛИПАЙ.',360,132,t=t)
    label(c,'ПИТОМЦЫ СО СВОИМИ ИСТОРИЯМИ',490,size=29)
    # Separate scales and parallax keep the hero fox readable.
    for idx,x,y,h,delay in [(1,225,875,.72,.10),(2,800,895,.76,.23),(3,210,1330,.64,.40),(4,807,1330,.63,.55)]:
        p=back(prog(t,delay,delay+.42))
        place(c,PETS[idx],x,y+17*math.sin(t*3+idx),h*max(.001,p),-7+idx*3)
    p=back(prog(t,.02,.5))
    place(c,PETS[0],515,1110+13*math.sin(t*4),1.30*max(.01,p))
    if t>.65: pill(c,'ТВОЯ МИЛАЯ КОМАНДА',515,1580,600)
    burst(c,515,1090,prog(t,.28,.9))

def cta(c,t):
    # Brand and CTA remain fully readable for over two seconds.
    for i in range(6):
        a=i*math.tau/6+t*.20
        x=515+650*math.cos(a); y=880+720*math.sin(a)
        place(c,TILES[i],x,y,.62,math.sin(a)*22)
    p=back(prog(t,0,.38))
    place(c,ICON,515,560,max(.01,p),-5*(1-clamp(p)))
    title(c,'MAHJONG',855,133,t=t,delay=.08)
    title(c,'RISE',1030,194,LIME,t=t,delay=.19)
    label(c,'СОБИРАЙ. СТРОЙ. ЗАЛИПАЙ.',1200,size=34)
    if t>.44:
        im=Image.new('RGBA',(790,148))
        d=ImageDraw.Draw(im)
        d.rounded_rectangle((0,0,789,147),44,fill=LIME)
        place(im,text('ТВОЙ ХОД',58,DARK),350,74)
        d.line((637,74,703,74),fill=DARK,width=8)
        d.line((679,50,703,74,679,98),fill=DARK,width=8)
        sc=back(prog(t,.44,.77))*(1+.012*math.sin(t*math.tau/B))
        place(c,im,515,1420,sc)
    label(c,'Играй в Mahjong Rise',1635,size=32)

CUTS=[4*B,12*B,18*B,24*B]
def frame(t):
    idx=sum(t>=cut for cut in CUTS)
    start=([0]+CUTS)[idx]
    c=background(t,idx==2)
    [hook,board,yard,pets,cta][idx](c,t-start)
    # Sharp diagonal wipe is a graphic transition, no blank frames.
    for cut in CUTS:
        if cut-.11<t<cut+.13:
            p=prog(t,cut-.11,cut+.13)
            x=mix(-1700,2100,p)
            ImageDraw.Draw(c).polygon([(x,0),(x+630,0),(x+50,H),(x-580,H)],fill=LIME)
    return c.convert('RGB')

def soundtrack(path):
    sr=48000; n=sr*DUR
    buf=np.zeros((n,2),np.float64); rng=np.random.default_rng(41)
    def add(at,s,pan=0):
        pos=round(at*sr)
        if pos<0:s=s[-pos:];pos=0
        size=min(len(s),n-pos)
        if size<=0:return
        buf[pos:pos+size,0]+=s[:size]*math.sqrt((1-pan)/2)
        buf[pos:pos+size,1]+=s[:size]*math.sqrt((1+pan)/2)
    def ts(d):return np.arange(round(sr*d))/sr
    for k in range(32):
        at=k*B
        q=ts(.33)
        # Punchy descending electronic kick.
        phase=2*np.pi*(49*q+105*.023*(1-np.exp(-q/.023)))
        add(at,.72*np.sin(phase)*np.exp(-q*15))
        if k%2==1:
            q=ts(.18); noise=rng.normal(0,1,len(q)); hi=noise-np.roll(noise,1)
            add(at,.17*hi*np.exp(-q*27)+.17*np.sin(2*np.pi*190*q)*np.exp(-q*32))
        for off in [0,.5]:
            q=ts(.075); noise=rng.normal(0,1,len(q)); hi=noise-np.roll(noise,1)
            add(at+off*B,.055*hi*np.exp(-q*68),(-1 if k%2 else 1)*.4)
        root=[146.83,130.81,110,130.81][(k//8)%4]
        q=ts(B*.86); env=np.minimum(q/.008,1)*np.exp(-q*9)
        bass=(np.sin(2*np.pi*root/2*q)+.25*np.sin(2*np.pi*root*q))*.23*env
        add(at+.04,bass)
        ratio=[2,3,4,3,2,4,3,2][k%8]
        q=ts(.50); freq=root*ratio
        lead=(np.sin(2*np.pi*freq*q)+.33*np.sin(2*np.pi*freq*2*q))*np.exp(-q*10)*np.minimum(q/.006,1)*.15
        add(at,lead,.25*math.sin(k));add(at+B*.75,lead*.23,-.3)
    for cut in CUTS:
        q=ts(.32); noise=rng.normal(0,1,len(q))
        smooth=np.convolve(noise,np.ones(12)/12,'same')
        env=np.sin(np.pi*q/.32)**2
        add(cut-.22,smooth*env*.34)
    for start in [.70,1.42,2.14]:
        q=ts(.30)
        s=(np.sin(2*np.pi*1320*q)+.5*np.sin(2*np.pi*1980*q))*.16*np.exp(-q*20)
        add(CUTS[0]+start+.40,s)
    # Final sonic logo resolves before the end, no abrupt audio cut.
    q=ts(1.1)
    add(14.05,sum(np.sin(2*np.pi*f*q) for f in [293.66,369.99,440])*np.exp(-q*4)*.10)
    buf*=np.minimum(np.arange(n)/sr/.008,1)[:,None]
    buf*=np.minimum((n-1-np.arange(n))/sr/.24,1)[:,None]
    buf=np.tanh(buf*1.3)
    buf*=.89/np.max(np.abs(buf))
    with wave.open(str(path),'wb') as f:
        f.setnchannels(2);f.setsampwidth(2);f.setframerate(sr)
        f.writeframes((buf*32767).astype('<i2').tobytes())

def main():
    BUILD.mkdir(parents=True,exist_ok=True)
    if '--preview' in sys.argv:
        marks=[.8,1.5,2.55,4.40,6.0,7.95,9.65,11.0,12.4,14.5]
        sheet=Image.new('RGB',(270*5,480*2),'#081E16')
        for i,t in enumerate(marks):
            im=frame(t); im.save(BUILD/f'frame-{t:05.2f}.jpg',quality=94)
            thumb=im.resize((270,480),Image.Resampling.LANCZOS)
            ImageDraw.Draw(thumb).text((8,453),f'{t:.2f}s',font=ImageFont.truetype(REG,17),fill='white',stroke_width=2,stroke_fill='black')
            sheet.paste(thumb,((i%5)*270,(i//5)*480))
        sheet.save(BUILD/'storyboard.jpg',quality=93)
        print(BUILD/'storyboard.jpg',flush=True)
        return
    wav=BUILD/'original-soundtrack.wav';soundtrack(wav)
    cmd=[str(FFMPEG),'-y','-loglevel','error','-f','rawvideo','-pix_fmt','rgb24','-s',f'{W}x{H}','-r',str(FPS),'-i','pipe:0','-i',str(wav),'-c:v','libx264','-pix_fmt','yuv420p','-preset','medium','-crf','18','-af','volume=0.75','-c:a','aac','-b:a','192k','-t','15','-movflags','+faststart',str(OUT)]
    proc=subprocess.Popen(cmd,stdin=subprocess.PIPE)
    try:
        for i in range(FPS*DUR):
            proc.stdin.write(frame(i/FPS).tobytes())
            if i%30==0:print(f'Render {i//30:02d}/15 s',flush=True)
    finally:proc.stdin.close()
    if proc.wait()!=0:raise RuntimeError('Video encoding failed')
    frame(13.0).save(BUILD/'poster.jpg',quality=95)
    print(f'Exported {OUT} ({OUT.stat().st_size:,} bytes)',flush=True)

if __name__=='__main__':main()
