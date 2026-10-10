from pathlib import Path

OUTPUT = Path(__file__).resolve().parents[1] / "ui" / "brand"
# Original chamfered lettering drawn for the approved poster; no external font outlines.
g={
'T':(100,'M0 0H100V30H66V140H34V30H0Z'),
'I':(40,'M0 0H40V140H0Z'),
'R':(100,'M0 0H85L100 15V73L77 94L106 140H65L37 97H32V140H0Z M32 29V65H64L70 59V35L64 29Z'),
'O':(100,'M14 0H86L100 14V126L86 140H14L0 126V14Z M34 30L30 34V106L34 110H66L70 106V34L66 30Z'),
'S':(100,'M14 0H100V31H36L32 35V52L36 56H86L100 70V126L86 140H0V109H64L68 105V88L64 84H14L0 70V14Z'),
'L':(100,'M0 0H34V108H100V140H0Z'),
'B':(100,'M0 0H85L100 15V56L86 70L100 84V125L85 140H0Z M32 28V57H63L69 51V34L63 28Z M32 84V112H63L69 106V90L63 84Z'),
'E':(100,'M0 0H100V30H34V55H90V85H34V110H100V140H0Z')}
parts=['<svg xmlns="http://www.w3.org/2000/svg" width="520" height="340" viewBox="0 0 520 340"><defs>']
for ch,(_,d) in g.items(): parts.append('<path id="'+ch+'" d="'+d+'" fill-rule="evenodd"/>')
parts.append('</defs><g id="lettering" transform="matrix(1,-0.06,-0.17,1,50,26)">')
for word,y,color in [('TIROS',0,'fff2d0'),('LIBRES',155,'3456e8')]:
 width=sum(g[c][0] for c in word)+8*(len(word)-1)
 parts.append('<g transform="translate(0,'+str(y)+') scale('+str(470/width)+',1.08)" fill="#'+color+'">')
 x=0
 for ch in word:
  parts.append('<use href="#'+ch+'" transform="translate('+str(x)+',0)"/>');x+=g[ch][0]+8
 parts.append('</g>')
parts.append('</g><defs><clipPath id="ink"><use href="#lettering"/></clipPath></defs><g clip-path="url(#ink)" fill="#211a2b" opacity="0.24">')
for i in range(1400):
 x=(i*71.37)%520;y=(i*43.71)%340
 parts.append('<circle cx="'+str(round(x,2))+'" cy="'+str(round(y,2))+'" r="0.65"/>')
parts.append('</g></svg>')
(OUTPUT / "wordmark.svg").write_text(''.join(parts)+'\n')

# Matching lettering for the fixed primary action; Button.text remains its semantic label.
g.update({
'J':(100,'M35 0H100V125L85 140H14L0 126V98H33V107L37 111H63L67 107V30H35Z'),
'U':(100,'M0 0H33V105L38 110H62L67 105V0H100V125L85 140H15L0 125Z'),
'G':(100,'M14 0H86L100 14V31H36L31 36V104L36 109H65L69 105V90H53V62H100V125L85 140H14L0 126V14Z'),
'A':(100,'M0 140L30 0H70L100 140H66L59 110H41L34 140Z M46 80H54L50 47Z')})
parts=['<svg xmlns="http://www.w3.org/2000/svg" width="350" height="110" viewBox="0 0 350 110"><g transform="matrix(0.64,-0.02,-0.13,0.68,18,6)" fill="#211a2b">']
x=0
for ch in 'JUGAR':
 parts.append('<path transform="translate('+str(x)+',0)" d="'+g[ch][1]+'" fill-rule="evenodd"/>')
 x+=g[ch][0]+7
parts.append('</g></svg>')
(OUTPUT / "play.svg").write_text(''.join(parts)+'\n')
