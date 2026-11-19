import zipfile,re,sys
from xml.etree import ElementTree as ET
ns={'w':'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
W='{%s}'%ns['w']
z=zipfile.ZipFile(sys.argv[1])
root=ET.fromstring(z.read('word/document.xml'))
body=root.find('w:body',ns)
out=[]
def ptext(p): return ''.join(t.text or '' for t in p.iter(W+'t'))
for el in body:
    tag=el.tag.split('}')[1]
    if tag=='p':
        st=el.find('w:pPr/w:pStyle',ns); s=st.get(W+'val') if st is not None else ''
        num=el.find('w:pPr/w:numPr',ns)
        t=ptext(el)
        has_img = el.find('.//w:drawing',ns) is not None
        if has_img: out.append('[IMAGE]')
        if not t.strip(): continue
        pre={'Heading1':'# ','Heading2':'## ','Heading3':'### ','Heading4':'#### ','Title':'TITLE: ','Caption':'CAPTION: '}.get(s,'')
        if num is not None and not pre: pre='- '
        out.append(pre+t)
    elif tag=='tbl':
        out.append('[TABLE]')
        for tr in el.findall('w:tr',ns):
            cells=[' '.join(ptext(p) for p in tc.iter(W+'p')).strip() for tc in tr.findall('w:tc',ns)]
            out.append('| '+' | '.join(cells)+' |')
        out.append('[/TABLE]')
    elif tag=='sectPr': pass
open(sys.argv[2],'w').write('\n\n'.join(out))
print(len(' '.join(out).split()),'words;', sum(1 for o in out if o=='[TABLE]'),'tables;', sum(1 for o in out if o=='[IMAGE]'),'images')
print([n for n in z.namelist() if 'media' in n])
