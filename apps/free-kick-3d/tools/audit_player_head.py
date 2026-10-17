"""Audit reconstructed head exports, plus unchanged gameplay/body contracts.

Pass an optional directory containing the pre-head GLBs for exact protected
surface comparison. Rig and animation checks always use persistent baselines.
"""
import collections
import hashlib
import json
import math
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
ASSETS = ROOT / 'apps/free-kick-3d/assets/footballer'
REPORT = ROOT / 'docs/research/player-head-2026-10-14'
helper = Path(__file__).with_name('audit_meshy_export.py')
namespace = {'__file__': str(helper)}
exec(helper.read_text().split('exports = []')[0], namespace)
GLB = namespace['GLB']


def surfaces(model):
    return {model.data['materials'][p['material']]['name']: p
            for mesh in model.data['meshes'] for p in mesh['primitives']}


def protected_rows(model):
    result = {}
    for name, primitive in surfaces(model).items():
        if name not in ['MeshyPlayer', 'Jersey', 'TailoredShorts', 'CollarKnit', 'GoalkeeperGloves']:
            continue
        attrs = primitive['attributes']
        keys = ['POSITION','TEXCOORD_0','TEXCOORD_1','JOINTS_0','WEIGHTS_0']
        rows = zip(*(model.values(attrs[k]) for k in keys))
        # Above the neck the old scan was deliberately removed. All garments,
        # hands, legs and gloves must remain exact authored data. The scalp
        # groom is intentionally refitted to the new skull.
        kept = [tuple(v for values in row for v in values) for row in rows
                if name != 'MeshyPlayer' or row[0][1] < 1.55]
        result[name] = collections.Counter(kept)
    return result


def audit(role, prior=None):
    new = GLB(ASSETS/f'meshy_{role}.glb')
    baseline = GLB(ASSETS/('meshy_player.glb' if role=='striker' else 'goalkeeper_v4.glb'))
    assert new.rig() == baseline.rig(), 'Bind pose changed'
    assert new.clips() == baseline.clips(), 'Animation channels changed'
    assert len(new.rig()) == 53
    primitives = surfaces(new)
    expected = {'MeshyPlayer','Jersey','TailoredShorts','CollarKnit','HairGroom','BeardGroom','BrowGroom','FaceSkin','FaceInterior','EyeSurface'}
    if role=='keeper': expected.add('GoalkeeperGloves')
    assert set(primitives) == expected, set(primitives)
    triangles, weight_error = {}, 0.
    for name,p in primitives.items():
        a=p['attributes']
        assert all(k in a for k in ['POSITION','NORMAL','TEXCOORD_0','TEXCOORD_1','JOINTS_0','WEIGHTS_0'])
        triangles[name]=new.data['accessors'][p['indices']]['count']//3
        for key in ['POSITION','NORMAL','TEXCOORD_0']:
            assert all(math.isfinite(x) for row in new.values(a[key]) for x in row), name
        assert all(abs(sum(x*x for x in n)-1)<1e-4 for n in new.values(a['NORMAL'])), name
        weights=new.values(a['WEIGHTS_0'])
        weight_error=max(weight_error,max(abs(sum(w)-1) for w in weights))
        assert all(w>=0 for row in weights for w in row)
        assert all(0<=j<53 for row in new.values(a['JOINTS_0']) for j in row)
        if name in ['FaceSkin','FaceInterior','EyeSurface']:
            positions=new.values(a['POSITION'])
            assert all(abs(x)<.15 and 1.54<y<1.91 and abs(z)<.20 for x,y,z in positions), name
            assert all(uv==(-2.,3.) for uv in new.values(a['TEXCOORD_1'])), 'Head receives jersey text'
    assert weight_error<1e-5
    assert 20000<triangles['FaceSkin']<50000
    eyes=primitives['EyeSurface']['attributes']
    ep=new.values(eyes['POSITION'])
    left=[p for p in ep if p[0]<0];right=[p for p in ep if p[0]>0]
    assert len(left)>200 and len(right)>200
    # True three-dimensional eyeballs, with enough depth behind the lids.
    assert all(max(p[2] for p in eye)-min(p[2] for p in eye)>.015 for eye in [left,right])
    assert all(max(w)>.999 for w in new.values(eyes['WEIGHTS_0']))
    normals = new.values(eyes['NORMAL'])
    for sign in [-1, 1]:
        pairs = [(p,n) for p,n in zip(ep,normals) if p[0]*sign>0]
        center = [(min(p[k] for p,n in pairs)+max(p[k] for p,n in pairs))/2 for k in range(3)]
        assert all(sum((p[k]-center[k])*n[k] for k in range(3))>0 for p,n in pairs), 'Inverted eyeball normals'
    protected = None
    if prior:
        old=GLB(prior/f'meshy_{role}.glb')
        old_rows,new_rows=protected_rows(old),protected_rows(new)
        for name in old_rows:
            assert old_rows[name]==new_rows[name], f'Protected surface changed: {name}'
        protected={name:sum(rows.values()) for name,rows in new_rows.items()}
    report_path=REPORT/f'{role}.json'
    report=json.loads(report_path.read_text())
    assert report['sha256']==hashlib.sha256(new.raw).hexdigest()
    report['audit']={'rig_and_clips_exact':True,'bones':len(new.rig()),'clips':sorted(new.clips()),
        'triangles':triangles,'maximum_weight_error':weight_error,'bytes':len(new.raw),
        'protected_vertices_exact':protected,'volumetric_eyes':True}
    report_path.write_text(json.dumps(report,indent=2)+'\n')
    print(role,json.dumps(report['audit']))

if __name__=='__main__':
    prior=Path(sys.argv[1]) if len(sys.argv)>1 else None
    for role in ['striker','keeper']:audit(role,prior)
