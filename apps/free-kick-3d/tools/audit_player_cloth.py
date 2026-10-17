"""Cloth-v2 acceptance gate: protected anatomy, rig/clips and skin weights."""
import hashlib
import json
import math
import sys
from pathlib import Path

ROOT=Path(__file__).resolve().parents[3]
helper=Path(__file__).with_name('audit_meshy_export.py')
namespace={'__file__':str(helper)}
exec(helper.read_text().split('exports = []')[0],namespace)
GLB=namespace['GLB']
ASSETS=ROOT/'apps/free-kick-3d/assets/footballer'

def protected(model):
    result=set()
    for primitive in model.data['meshes'][0]['primitives']:
        attrs=primitive['attributes']
        rows=[model.values(attrs[name]) for name in ['POSITION','TEXCOORD_0','JOINTS_0','WEIGHTS_0']]
        for row in zip(*rows):
            if row[0][1]>1.63 or row[0][1]<.20:
                result.add(row)
    return result

def audit(role):
    original=GLB(ASSETS/'meshy_player.glb')
    source=original if role=='striker' else GLB(ASSETS/'goalkeeper_v4.glb')
    new=GLB(ASSETS/f'meshy_{role}.glb')
    assert new.rig()==source.rig()
    assert new.clips()==source.clips(), 'Animation clips changed'
    assert protected(new)==protected(original), 'Face/hair/boots or their UV/weights changed'
    triangles=0
    max_error=0
    for primitive in new.data['meshes'][0]['primitives']:
        attrs=primitive['attributes']
        assert 'TEXCOORD_0' in attrs and 'TEXCOORD_1' in attrs
        triangles+=new.data['accessors'][primitive['indices']]['count']//3
        assert all(math.isfinite(v) for row in new.values(attrs['POSITION']) for v in row)
        assert all(0<=j<53 for row in new.values(attrs['JOINTS_0']) for j in row)
        max_error=max(max_error,max(abs(sum(row)-1) for row in new.values(attrs['WEIGHTS_0'])))
    assert max_error<1e-5
    path=ROOT/f'docs/research/cloth-quality-2026-10-11/{role}.json'
    report=json.loads(path.read_text())
    assert report['runtime_sha256']==hashlib.sha256(new.raw).hexdigest()
    assert triangles<report['triangles_before']
    report['export_audit']={'rig_and_clips_exact':True,'face_hair_boots_uv_weights_exact':True,
        'triangles':triangles,'reduction_percent':round((1-triangles/report['triangles_before'])*100,2),
        'maximum_weight_error':max_error,'bytes':len(new.raw)}
    path.write_text(json.dumps(report,indent=2)+'\n')
    print(role,json.dumps(report['export_audit']))

if __name__=='__main__':
    for role in (sys.argv[1:] or ['striker','keeper']): audit(role)
